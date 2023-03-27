//
//  Unit.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/03/05.
//

import Foundation

enum Unit: Int, CaseIterable {
    case kiloPerHour
    case meterPerSecond
    
    var name: String {
        switch self {
        case .kiloPerHour: return "km/h"
        case .meterPerSecond: return "m/s"
        }
    }
}

extension Double {
    /// 速度の単位変換
    func convert(to: Unit, from: Unit = .meterPerSecond) -> Double {
        switch (to, from) {
        case (.kiloPerHour, .meterPerSecond):
            return self * 3.6
        case (.meterPerSecond, .kiloPerHour):
            return self / 3.6
        default:
            return self
        }
    }
}
