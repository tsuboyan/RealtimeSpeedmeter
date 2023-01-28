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
    @Published var speed: Double = 0
    
    var speedKiloMeter: Double {
        abs(speed * 60)
    }
    
    var stopping: Bool {
        acc < 0.005
    }
}

@MainActor final class SpeedmeterPresenter {
    let fps: Double = 30
    let accThresh: Double = 0.01 // この加速度以上であれば速度を計算する (ドリフト防止)
    let stoppingThresh: Double = 0.005 // この加速度以下の状態が stoppingResetInterval 秒間続くと速度をリセットする (ドリフト防止)
    let stoppingResetInterval: Double = 5.0
    let sensor: AccelerationSensor
    let state: SpeedmeterViewState
    private var smoothedHorizontalAcc: Double = 0
    private var stoppingCounter: Int = 0
    private var cancellables: Set<AnyCancellable> = []
    
    init(state: SpeedmeterViewState) {
        sensor = AccelerationSensor(delta: 1 / fps)
        self.state = state
    }
    
    func onAppear() {
        sensor.updateMotion.receive(on: RunLoop.main).sink(receiveValue: { [weak self] motion in
            guard let strongSelf = self else { return }
            let ax = motion.userAcceleration.x
            let ay = motion.userAcceleration.y
            let az = motion.userAcceleration.z
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            
            let horizontalAcc = SpeedCalculator.calculateHorizontalComponent(x: ax, y: ay, z: az, roll: roll, pitch: pitch)
            strongSelf.state.acc = SpeedCalculator.smooth(current: horizontalAcc, previous: strongSelf.smoothedHorizontalAcc)
            strongSelf.state.speed = SpeedCalculator.calculateSpeed(currentSpeed: strongSelf.state.speed,
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
                strongSelf.state.speed = 0
                strongSelf.stoppingCounter = 0
            }
        }).store(in: &cancellables)
    }
    
    func onTapStart() {
        sensor.startAccelerometer()
    }
    
    func onTapStop() {
        state.speed = 0
        sensor.stopAccelerometer()
    }
    
    func onTapReset() {
        state.speed = 0
    }
}
