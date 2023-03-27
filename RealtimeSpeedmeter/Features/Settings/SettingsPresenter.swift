//
//  SettingsPresenter.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/02/28.
//

import Foundation

@MainActor final class SettingsPresenter: ObservableObject {
    @MainActor struct ViewState {
        fileprivate(set) var unit: Unit
        fileprivate(set) var maximumSpeed: Int
    }
    
    @Published private(set) var state: ViewState
    
    init() {
        state = .init(unit: UserDefaultsClient.unit,
                      maximumSpeed: UserDefaultsClient.maximumSpeed)
    }
    
    func onChangeUnit(_ unit: Unit) {
        state.unit = unit
        UserDefaultsClient.unit = unit
    }
    
    func onChangeMaximumSpeed(_ speed: Int) {
        state.maximumSpeed = speed
        UserDefaultsClient.maximumSpeed = speed
    }
}
