//
//  SpeedmeterPresenter.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/23.
//

import Combine
import Foundation
import UIKit

@MainActor final class SpeedmeterPresenter: ObservableObject {
    @MainActor struct ViewState  {
        fileprivate var speedmeterItem = SpeedmeterItem()
        fileprivate(set) var unit: Unit = .kilometerPerHour
        fileprivate(set) var maximumSpeed: Int = 0
        fileprivate(set) var colorTheme: ColorTheme = .auto
        fileprivate(set) var isFirstDisplayed = false
        fileprivate(set) var isSensorActive = true
        
        var accelerationSpeed: Double {
            let speed = speedmeterItem.accelerationSpeed.convertFromMPS(to: unit)
            return abs(speed)
        }
        
        var acceleration: Double {
            speedmeterItem.acceleration
        }
        
        var measurementMethod: String {
            let accelerationText = String(localized: "acceleration_title")
            let gpsText = "GPS"
            return SpeedCalculator.isGpsAvailable(speedmeterItem.gpsSpeed) ?
            (accelerationText + " + " + gpsText) : accelerationText
        }
        
        var accelerationState: String {
            return speedmeterItem.accerationState.name
        }
    }
    
    @Published private(set) var state: ViewState
    let usecase: SpeedmeterUsecase
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        state = .init()
        let accelerationSensor = AccelerationSensor()
        let gpsSensor = GpsSensor()
        usecase = SpeedmeterUsecase(accelerationSensor: accelerationSensor,
                                         gpsSensor: gpsSensor)
    }
    
    func onAppear() {
        state.unit = UserDefaultsClient.unit
        state.maximumSpeed = UserDefaultsClient.maximumSpeed
        state.colorTheme = UserDefaultsClient.colorTheme
        
        usecase.setup()
        usecase.updateSpeedmeter.receive(on: RunLoop.main).sink { [weak self] speedmeterItem in
            self?.state.speedmeterItem = speedmeterItem
        }.store(in: &cancellables)
        usecase.start()
        
        // Speedmeter画面を表示している間スリープにしない
        UIApplication.shared.isIdleTimerDisabled = true
        
        UserDefaultsClient.incrementNumberOfSpeedmeterDisplayed()
    }
    
    func onDisappear() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func onTapReset() {
        usecase.reset()
    }
    
    #if DEBUG
        func onTapStartStop() {
            if state.isSensorActive {
                usecase.stop()
                state.isSensorActive = false
            } else {
                usecase.start()
                state.isSensorActive = true
            }
        }
    #endif
}
