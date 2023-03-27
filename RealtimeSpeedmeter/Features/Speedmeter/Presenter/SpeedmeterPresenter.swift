//
//  SpeedmeterPresenter.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/23.
//

import Combine
import Foundation

@MainActor final class SpeedmeterPresenter: ObservableObject {
    @MainActor struct ViewState  {
        fileprivate var speedmeterItem = SpeedmeterItem()
        fileprivate(set) var unit: Unit
        fileprivate(set) var maximumSpeed: Int
        fileprivate(set) var isSensorActive = true
        
        var accelerationSpeed: Double {
            let speed = speedmeterItem.accelerationSpeed.convert(to: unit)
            return abs(speed)
        }
        
        var acceleration: Double {
            speedmeterItem.acceleration
        }
        
        var measurementMethod: String {
            SpeedCalculator.isGpsAvailable(speedmeterItem.gpsSpeed) ? "加速度 + GPS" : "加速度"
        }
    }
    
    @Published private(set) var state: ViewState
    let usecase: SpeedmeterUsecase
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        state = .init(unit: .kiloPerHour, maximumSpeed: 0)
        let accelerationSensor = AccelerationSensor()
        let gpsSensor = GpsSensor()
        usecase = SpeedmeterUsecase(accelerationSensor: accelerationSensor,
                                         gpsSensor: gpsSensor)
    }
    
    func onAppear() {
        state.unit = UserDefaultsClient.unit
        state.maximumSpeed = UserDefaultsClient.maximumSpeed
        
        usecase.setup()
        usecase.updateSpeedmeter.receive(on: RunLoop.main).sink { [weak self] speedmeterItem in
            self?.state.speedmeterItem = speedmeterItem
        }.store(in: &cancellables)
        usecase.start()
    }
    
    func onTapStartStop() {
        if state.isSensorActive {
            usecase.stop()
            state.isSensorActive = false
        } else {
            usecase.start()
            state.isSensorActive = true
        }
    }
    
    func onTapReset() {
        usecase.reset()
    }
}
