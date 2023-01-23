//
//  SpeedmeterPresenter.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/23.
//

import Combine
import Foundation

@MainActor final class SpeedmeterViewState: ObservableObject {
    @Published var accelerationY: Double = 0
    @Published var speedY: Double = 0
    
    var speedYKM: Double {
        (speedY / 1000) * 60
    }
}

@MainActor final class SpeedmeterPresenter {
    let delta: Double = 0.1
    let sensor: AccelerationSensor
    let state: SpeedmeterViewState
    private var cancellables: Set<AnyCancellable> = []
    
    init(state: SpeedmeterViewState) {
        sensor = AccelerationSensor(delta: delta)
        self.state = state
    }
    
    func onAppear() {
        sensor.updateMotion.receive(on: RunLoop.main).sink(receiveValue: { [weak self] motion in
            guard let strongSelf = self else { return }
            let acceleration = motion.userAcceleration.y
            strongSelf.state.accelerationY = acceleration
            strongSelf.state.speedY = SpeedCalculator.calculateSpeed(currentSpeed: strongSelf.state.speedY, acceleration: acceleration, delta: strongSelf.delta)
            print(motion.userAcceleration.y)
        }).store(in: &cancellables)
    }
    
    func onTapStart() {
        sensor.startAccelerometer()
    }
    
    func onTapStop() {
        state.speedY = 0
        sensor.stopAccelerometer()
    }
}
