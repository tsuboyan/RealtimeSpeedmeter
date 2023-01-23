//
//  SpeedCalculator.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/24.
//

import Foundation

struct SpeedCalculator {
    static func calculateSpeed(currentSpeed: Double, acceleration: Double, delta: Double) -> Double {
        currentSpeed + (acceleration * delta)
    }
}
