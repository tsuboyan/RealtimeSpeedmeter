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
    enum Constants {
        static let fps: Double = 100
        /// この加速度以下の状態が stoppingResetInterval 秒間続くと速度をリセットする(ドリフト防止)
        static let stoppingStdevThresh: Double = 0.01
        static let stoppingResetInterval: Double = 1.0
        /// 標準偏差による停止判定用の配列の要素数
        static let stoppingAccelerationsCapacity = 10
    }
    
    enum AccelerationState {
        /// 加速中
        case accelerating
        /// 減速中
        case decelerating
        /// 巡航中・停止中
        case stay
    }
    
    let updateSpeedmeter = PassthroughSubject<SpeedmeterItem, Never>()
    
    private let accelerationSensor: AccelerationSensor
    private let gpsSensor: GpsSensor
    
    private let accelerationParam = CurrentValueSubject<(acceleration: Double, speed: Double), Never>((0, 0))
    private let gpsParamsSubject = CurrentValueSubject<GpsParams, Never>(GpsParams(cllocation: CLLocation()))
    
    /// 標準偏差による停止判定用の配列
    private var unsmoothedAccelerationRingArray = RingArray(capacity: Constants.stoppingAccelerationsCapacity)
    
    private var updatedDate = Date()
    private var stoppingCounter: Int = 0
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
            
            let currentAccelerationSpeed = self.accelerationParam.value.speed
            
            let nextAccelerationSpeed = isStopping ? currentAccelerationSpeed : SpeedCalculator.calculateNextSpeed(
                currentSpeed: currentAccelerationSpeed,
                acceleration: acceleration,
                delta: elapsedTime)
            
            // 加速・減速判定
            if acceleration > 0.1 { self.accerationState = .accelerating }
            if acceleration < -0.1 { self.accerationState = .decelerating }
            if self.accerationState == .accelerating, acceleration < 0 ||
                self.accerationState == .decelerating, acceleration > 0 { self.accerationState = .stay }
            
            // 加速はACC・GPSの大きい方、減速中は小さい方の速度を採用する
            let mergedSpeed: Double
            switch self.accerationState {
            case .accelerating, .stay:
                mergedSpeed = max(nextAccelerationSpeed, self.gpsParamsSubject.value.speed)
            case .decelerating:
                if SpeedCalculator.isGpsAvailable(self.gpsParamsSubject.value.speed) {
                    mergedSpeed = min(nextAccelerationSpeed, self.gpsParamsSubject.value.speed)
                } else {
                    mergedSpeed = nextAccelerationSpeed
                }
            }
            self.accelerationParam.send((acceleration: acceleration, speed: mergedSpeed))
            
            // 一定秒数間停止していたら速度をリセットする
            if isStopping {
                self.stoppingCounter += 1
            } else {
                self.stoppingCounter = 0
            }
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
                    gpsAccuracy: gpsParams.locationAccuracy)
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
        self.accelerationParam.send((acceleration: acc, speed: 0))
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
