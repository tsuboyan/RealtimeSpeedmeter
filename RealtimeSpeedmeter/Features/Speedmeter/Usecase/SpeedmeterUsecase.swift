//
//  SpeedmeterUsecase.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/02/22.
//

import Combine
import Foundation
import CoreLocation

struct GpsParams {
    let speed: Double
    let location: (lat: Double, lng: Double)
    let speedAccuracy: Double
    let locationAccuracy: Double
    
    init(cllocation: CLLocation) {
        self.speed = cllocation.speed
        self.location = (cllocation.coordinate.latitude, cllocation.coordinate.longitude)
        self.speedAccuracy = cllocation.speedAccuracy
        self.locationAccuracy = cllocation.horizontalAccuracy
    }
}

final class SpeedmeterUsecase {
    
    let updateSpeedmeter = PassthroughSubject<SpeedmeterItem, Never>()
    
    private let accelerationSensor: AccelerationSensor
    private let gpsSensor: GpsSensor
    
    private let accelerationParam = CurrentValueSubject<(acceleration: Double, speed: Double, accState: AccelerationState), Never>((0, 0, .stay))
    private let gpsParamsSubject = CurrentValueSubject<GpsParams, Never>(GpsParams(cllocation: CLLocation()))
    
    /// 標準偏差による停止判定用の配列
    private var unsmoothedAccelerationRingArray = RingArray(capacity: Constants.stoppingAccelerationsCapacity)
    
    private var updatedDate = Date()
    private var stoppingCounter: Int = 0
    
    // 加速度ステート用
    private var stayingCounter: Int = 0
    private var accerationCounter: Int = 0
    private var decelerationCounter: Int = 0
    
    private var accerationState: AccelerationState = .stay
    
    private var cancellables: Set<AnyCancellable> = []
    
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
            guard let self = self else { return }
            
            let elapsedTime = Date().timeIntervalSince(self.updatedDate)
            
            let horizontalAcceleration = SpeedCalculator.calculateHorizontalAcceleration(motion)
            self.unsmoothedAccelerationRingArray.append(horizontalAcceleration)
            let isStopping = self.isStopping(accelerationStdev: self.unsmoothedAccelerationRingArray.stdev)
            let acceleration = SpeedCalculator.smooth(current: horizontalAcceleration, previous: self.accelerationParam.value.acceleration)
            let previousAccelerationSpeed = self.accelerationParam.value.speed
            let accelerationSpeed = isStopping ? previousAccelerationSpeed : SpeedCalculator.calculateSpeed(
                previousSpeed: previousAccelerationSpeed,
                acceleration: acceleration,
                delta: elapsedTime)
            
            
            if acceleration > Constants.accelerationStateChangeThresh {
                if self.accerationCounter > Int(Constants.fps * Constants.stateHoldTime) {
                    self.accerationState = .accelerating
                }
                self.accerationCounter += 1
                self.decelerationCounter = 0
                self.stayingCounter = 0
            }
            else if acceleration < -1 * Constants.accelerationStateChangeThresh {
                if self.decelerationCounter > Int(Constants.fps * Constants.stateHoldTime) {
                    self.accerationState = .decelerating
                }
                self.accerationCounter = 0
                self.decelerationCounter += 1
                self.stayingCounter = 0
            }
            else {
                if self.stayingCounter > Int(Constants.fps * Constants.stateHoldTime) {
                    self.accerationState = .stay
                }
                self.accerationCounter = 0
                self.decelerationCounter = 0
                self.stayingCounter += 1
            }
            
            // 加速度ステートが加速中の時はACC・GPSの大きい方、減速中の時は小さい方の速度を採用する
            // 加速度の揺れでステートが振動しないように、加速度ステートは指定した時間が経過しないと変化できないようにする
            
            let mergedSpeed: Double
            switch self.accerationState {
            case .accelerating:
                if SpeedCalculator.isGpsAvailable(self.gpsParamsSubject.value.speed) {
                    mergedSpeed = max(accelerationSpeed, self.gpsParamsSubject.value.speed)
                } else {
                    mergedSpeed = accelerationSpeed
                }
            case .decelerating:
                if SpeedCalculator.isGpsAvailable(self.gpsParamsSubject.value.speed) {
                    mergedSpeed = min(accelerationSpeed, self.gpsParamsSubject.value.speed)
                } else {
                    mergedSpeed = accelerationSpeed
                }
            case .stay:
                if SpeedCalculator.isGpsAvailable(self.gpsParamsSubject.value.speed) {
                    mergedSpeed = self.gpsParamsSubject.value.speed
                } else {
                    mergedSpeed = accelerationSpeed
                }
            }
            self.accelerationParam.send((acceleration: acceleration, speed: mergedSpeed, accState: self.accerationState))
            
            // 一定秒数間停止していたら速度をリセットする
            self.stoppingCounter = isStopping ? self.stoppingCounter + 1 : 0

            if self.stoppingCounter > Int(Constants.fps * Constants.stoppingResetInterval) {
                self.reset()
                self.stoppingCounter = 0
                self.accerationState = .stay
            }
            
            #if DEBUG
                self.csvLogger.appendBody(motion: motion,
                                          horizontalAcceleration: horizontalAcceleration,
                                          acceleration: acceleration,
                                          accelerationSpeed: mergedSpeed,
                                          stoppingCounter: self.stoppingCounter,
                                          gpsParams: self.gpsParamsSubject.value)
            #endif
            
            
            self.updatedDate = Date()
        }).store(in: &cancellables)
        
        accelerationParam.combineLatest(gpsParamsSubject)
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
        accelerationSensor.startAccelerometer(delta: 1 / Constants.fps)
        gpsSensor.startGpsSensor()
    }
    
    func stop() {
        reset()
        accelerationSensor.stopAccelerometer()
        gpsSensor.stopGpsSensor()
        #if DEBUG
            csvLogger.save()
            csvLogger.clearBody()
        #endif
    }
    
    func reset() {
        let acc = self.accelerationParam.value.acceleration
        self.accelerationParam.send((acceleration: acc, speed: 0, accState: .stay))
    }
}

private extension SpeedmeterUsecase {
    struct RingArray {
        let capacity: Int
        private var array: [Double]
        private(set) public var latestIndex: Int = -1
        private(set) public var oldestIndex: Int = 0
        
        var count: Int {
            return (latestIndex - oldestIndex + 1)
        }
        
        var stdev: Double {
            stdev(array)
        }
        
        init(capacity: Int) {
            self.capacity = capacity
            self.array = Array(repeating: 0, count: capacity)
        }
        
        mutating func append(_ value: Double) {
            latestIndex += 1
            array[latestIndex % capacity] = value
            
            if capacity < count {
                oldestIndex += 1
            }
        }
        
        private func stdev(_ array : [Double]) -> Double {
            let length = Double(array.count)
            let average = array.reduce(0, {$0 + $1}) / length
            let sumOfSquaredAverageDiff = array.map { pow($0 - average, 2.0)}.reduce(0, {$0 + $1})
            return sqrt(sumOfSquaredAverageDiff / length)
        }
    }
    
    /// 端末の動きが止まっているか (加速度の標準偏差≒0で停止判断)
    /// センサの特性上運動が停止しても加速度はすぐには0にならないが、振動は収まるため標準偏差の値を使って判定する
    private func isStopping(accelerationStdev: Double) -> Bool {
        return accelerationStdev < Constants.stoppingStdevThresh
    }
}
