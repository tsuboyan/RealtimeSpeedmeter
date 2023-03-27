//
//  SpeedmeterItem.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/03/06.
//

import Foundation

struct SpeedmeterItem {
    let acceleration: Double
    let accelerationSpeed: Double
    let gpsSpeed: Double
    let gpsAccuracy: Double
    
    init() {
        self.init(acceleration: 0, accelerationSpeed: 0, gpsSpeed: 0, gpsAccuracy: 0)
    }
    
    init(acceleration: Double, accelerationSpeed: Double, gpsSpeed: Double, gpsAccuracy: Double) {
        self.acceleration = acceleration
        self.accelerationSpeed = accelerationSpeed
        self.gpsSpeed = gpsSpeed
        self.gpsAccuracy = gpsAccuracy
    }
}
