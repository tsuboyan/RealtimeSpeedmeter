//
//  UserDefaultsClient.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/03/09.
//

import Foundation

enum UserDefaultsClient {
    private enum IntItem: String {
        case unit
        case maximumSpeed
    }
    
    private static func set(value: Int, forKey item: IntItem) {
        UserDefaults.standard.set(value, forKey: item.rawValue)
    }
    
    private static func integer(forKey item: IntItem) -> Int {
        UserDefaults.standard.integer(forKey: item.rawValue)
    }
}

extension UserDefaultsClient {
    static var unit: Unit {
        get {
            Unit(rawValue: integer(forKey: .unit)) ?? .kiloPerHour
        }
        set {
            set(value: newValue.rawValue, forKey: .unit)
        }
    }
    
    static var maximumSpeed: Int {
        get {
            let defaultMaximumSpeed = 30
            // integer(forKey: .maximumSpeed) はdefaultで0を返す
            let value = integer(forKey: .maximumSpeed)
            return value == 0 ? defaultMaximumSpeed : value
        }
        set {
            set(value: newValue, forKey: .maximumSpeed)
        }
    }
}
