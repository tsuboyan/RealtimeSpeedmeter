//
//  SpeedmeterPresenter.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/23.
//

import Combine
import Foundation

@MainActor final class SpeedmeterViewState: ObservableObject {
    @Published var acc: Double = 0
    @Published var speedAcc: Double = 0
    @Published var speedGps: Double = 0
    
    var speedAccKiloMeter: Double {
        abs(speedAcc * 60) * 3.6
    }
    
    var speedGpsKiloMeter: Double {
        speedGps * 3.6
    }
    
    // FIXME: デバッグ用途なので後で消す
    var stopping: Bool {
        acc < 0.005
    }
}

@MainActor final class SpeedmeterPresenter {
    let fps: Double = 30
    let accThresh: Double = 0.01 // この加速度以上であれば速度を計算する (ドリフト防止)
    let stoppingThresh: Double = 0.01 // この加速度以下の状態が stoppingResetInterval 秒間続くと速度をリセットする (ドリフト防止)
    let stoppingResetInterval: Double = 3.0
    let accSensor: AccelerationSensor
    let gpsSensor: GpsSensor
    let state: SpeedmeterViewState
    private var smoothedHorizontalAcc: Double = 0
    private var stoppingCounter: Int = 0
    private var cancellables: Set<AnyCancellable> = []
    
    let csvService = CSVService()
    var csvData = "time, ax, ay, az, roll, pitch, HorizontalAcc, SmoothedAcc, SpeedACC, SpeedGPS, StoppingCounter"
    
    init(state: SpeedmeterViewState) {
        accSensor = AccelerationSensor(delta: 1 / fps)
        gpsSensor = GpsSensor()
        self.state = state
    }
    
    func onAppear() {
        gpsSensor.requestAuthorize()
        
        gpsSensor.updateLocation.receive(on: RunLoop.main).sink(receiveValue: { [weak self] location in
            self?.state.speedGps = location.speed
        }).store(in: &cancellables)
        
        accSensor.updateMotion.receive(on: RunLoop.main).sink(receiveValue: { [weak self] motion in
            guard let strongSelf = self else { return }
            let ax = motion.userAcceleration.x
            let ay = motion.userAcceleration.y
            let az = motion.userAcceleration.z
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            
            let horizontalAcc = SpeedCalculator.calculateHorizontalComponent(x: ax, y: ay, z: az, roll: roll, pitch: pitch)
            strongSelf.state.acc = SpeedCalculator.smooth(current: horizontalAcc, previous: strongSelf.smoothedHorizontalAcc)
            strongSelf.state.speedAcc = SpeedCalculator.calculateSpeed(currentSpeed: strongSelf.state.speedAcc,
                                                                    acc: strongSelf.state.acc,
                                                                    delta: 1 / strongSelf.fps,
                                                                    accThresh: strongSelf.accThresh)
            // 一定秒数秒間acc≒0が続いたら停止しているとみなしてリセット
            if strongSelf.state.acc < strongSelf.stoppingThresh {
                strongSelf.stoppingCounter += 1
            } else {
                strongSelf.stoppingCounter = 0
            }
            if strongSelf.stoppingCounter > Int(strongSelf.fps * strongSelf.stoppingResetInterval) {
                strongSelf.state.speedAcc = 0
                strongSelf.stoppingCounter = 0
            }
            
            let log = "\n\(Date().description), \(ax), \(ay), \(az), \(roll), \(pitch), \(horizontalAcc), \(strongSelf.state.acc), \(strongSelf.state.speedAccKiloMeter), \(strongSelf.state.speedGpsKiloMeter), \(strongSelf.stoppingCounter)"
            strongSelf.csvData += log
        }).store(in: &cancellables)
    }
    
    func onTapStart() {
        accSensor.startAccelerometer()
        gpsSensor.startGpsSensor()
    }
    
    func onTapStop() {
        state.speedAcc = 0
        accSensor.stopAccelerometer()
        gpsSensor.stopGpsSensor()
        csvService.saveCSV(dataStr: csvData)
    }
    
    func onTapReset() {
        state.speedAcc = 0
    }
}
