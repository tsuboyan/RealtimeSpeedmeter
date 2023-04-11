//
//  SpeedmeterUsecase.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/02/22.
//

import Combine
import Foundation
import CoreLocation
import CoreMotion

final class SpeedmeterUsecase {
    let updateSpeedmeter = PassthroughSubject<SpeedmeterItem, Never>()
    
    private let accelerationParamSubject = CurrentValueSubject<(acceleration: Double, speed: Double, accState: AccelerationState), Never>((0, 0, .stay))
    private let gpsParamsSubject = CurrentValueSubject<GpsParams, Never>(GpsParams(cllocation: CLLocation()))
    
    private let accelerationSensor: AccelerationSensor
    private let gpsSensor: GpsSensor
    
    /// 標準偏差による停止判定用の配列
    private var unsmoothedAccelerationRingArray = RingArray(capacity: Constants.stoppingAccelerationsCapacity)
    
    /// 定めた閾値を超えたら停止判定する
    private var stoppingCounter: Int = 0
    
    // 定めた閾値を超えたカウンタをaccerationStateにセットする
    private var stayingCounter: Int = 0
    private var accerationCounter: Int = 0
    private var decelerationCounter: Int = 0
    private var accerationState: AccelerationState = .stay
    
    private var cancellables: Set<AnyCancellable> = []
    private var updatedDate = Date()
    private let csvLogger = CSVLogger()
    
    init(accelerationSensor: AccelerationSensor, gpsSensor: GpsSensor) {
        self.accelerationSensor = accelerationSensor
        self.gpsSensor = gpsSensor
    }
    
    func setup() {
        gpsSensor.requestAuthorize()
        
        gpsSensor.updateLocation.receive(on: RunLoop.main).sink(receiveValue: { [weak self] location in
            self?.gpsParamsSubject.send(GpsParams(cllocation: location))
        }).store(in: &cancellables)
        
        accelerationSensor.updateMotion.receive(on: RunLoop.main).sink(receiveValue: { [weak self] motion in
            self?.updateSpeedmeterItem(from: motion)
        }).store(in: &cancellables)
        
        accelerationParamSubject.combineLatest(gpsParamsSubject)
            .sink { [weak self] (accParam, gpsParams) in
                self?.updateSpeedmeter.send(SpeedmeterItem(
                    acceleration: accParam.acceleration,
                    accelerationSpeed: accParam.speed,
                    gpsSpeed: gpsParams.speed,
                    gpsAccuracy: gpsParams.locationAccuracy,
                    accerationState: accParam.accState
                )
                )
            }.store(in: &cancellables)
        
        #if DEBUG
            csvLogger.setRealtimeSpeedMeterLogHeader()
        #endif
    }
    
    func start() {
        accelerationSensor.start(delta: 1 / Constants.fps)
        gpsSensor.start()
    }
    
    func stop() {
        reset()
        accelerationSensor.stop()
        gpsSensor.stop()
        #if DEBUG
            csvLogger.save()
            csvLogger.clearBody()
        #endif
    }
    
    func reset() {
        let acc = self.accelerationParamSubject.value.acceleration
        self.accelerationParamSubject.send((acceleration: acc, speed: 0, accState: .stay))
    }
}

private extension SpeedmeterUsecase {
    func updateSpeedmeterItem(from motion: CMDeviceMotion) {
        let elapsedTime = Date().timeIntervalSince(updatedDate)
        
        let horizontalAcceleration = SpeedCalculator.calculateHorizontalAcceleration(motion)
        unsmoothedAccelerationRingArray.append(horizontalAcceleration)
        let isStopping = SpeedCalculator.isStopping(accelerationStdev: unsmoothedAccelerationRingArray.stdev)
        let acceleration = SpeedCalculator.smooth(current: horizontalAcceleration, previous: accelerationParamSubject.value.acceleration)
        let previousAccelerationSpeed = accelerationParamSubject.value.speed
        let accelerationSpeed = isStopping ? previousAccelerationSpeed : SpeedCalculator.calculateSpeed(
            previousSpeed: previousAccelerationSpeed,
            acceleration: acceleration,
            delta: elapsedTime)
        
        
        if acceleration > Constants.accelerationStateChangeThresh {
            if accerationCounter > Int(Constants.fps * Constants.stateHoldTime) {
                accerationState = .accelerating
            }
            accerationCounter += 1
            decelerationCounter = 0
            stayingCounter = 0
        } else if acceleration < -1 * Constants.accelerationStateChangeThresh {
            if decelerationCounter > Int(Constants.fps * Constants.stateHoldTime) {
                accerationState = .decelerating
            }
            accerationCounter = 0
            decelerationCounter += 1
            stayingCounter = 0
        } else {
            if stayingCounter > Int(Constants.fps * Constants.stateHoldTime) {
                accerationState = .stay
            }
            accerationCounter = 0
            decelerationCounter = 0
            stayingCounter += 1
        }
        
        // 加速中はACC・GPSの大きい方、減速中の時は小さい方の速度を採用する
        // 加速度の揺れでステートが振動しないように、加速度ステートは指定した時間が経過しないと変化できないようにする
        let mergedSpeed: Double
        switch accerationState {
        case .accelerating:
            if SpeedCalculator.isGpsAvailable(gpsParamsSubject.value.speed) {
                mergedSpeed = max(accelerationSpeed, gpsParamsSubject.value.speed)
            } else {
                mergedSpeed = accelerationSpeed
            }
        case .decelerating:
            if SpeedCalculator.isGpsAvailable(gpsParamsSubject.value.speed) {
                mergedSpeed = min(accelerationSpeed, gpsParamsSubject.value.speed)
            } else {
                mergedSpeed = accelerationSpeed
            }
        case .stay:
            if SpeedCalculator.isGpsAvailable(gpsParamsSubject.value.speed) {
                mergedSpeed = gpsParamsSubject.value.speed
            } else {
                mergedSpeed = accelerationSpeed
            }
        }
        accelerationParamSubject.send((acceleration: acceleration, speed: mergedSpeed, accState: accerationState))
        
        // 一定時間停止していたら速度をリセットする
        stoppingCounter = isStopping ? stoppingCounter + 1 : 0
        if stoppingCounter > Int(Constants.fps * Constants.stoppingResetInterval) {
            reset()
            stoppingCounter = 0
            accerationState = .stay
        }
        
        #if DEBUG
            csvLogger.appendBody(motion: motion,
                                      horizontalAcceleration: horizontalAcceleration,
                                      acceleration: acceleration,
                                      accelerationSpeed: mergedSpeed,
                                      stoppingCounter: stoppingCounter,
                                      gpsParams: gpsParamsSubject.value)
        #endif
        updatedDate = Date()
    }
}
