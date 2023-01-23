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
}

@MainActor final class SpeedmeterPresenter {
    let sensor = AccelerationSensor()
    let state: SpeedmeterViewState
    private var cancellables: Set<AnyCancellable> = []
    
    init(state: SpeedmeterViewState) {
        self.state = state
    }
    
    func onAppear() {
        sensor.updateMotion.receive(on: RunLoop.main).sink(receiveValue: { [weak self] motion in
            self?.state.accelerationY = motion.userAcceleration.y
            print(motion.userAcceleration.y)
        }).store(in: &cancellables)
    }
    
    func onTapStart() {
        sensor.startAccelerometer()
    }
    
    func onTapStop() {
        sensor.stopAccelerometer()
    }
}
