//
//  SpeedCalculator.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/24.
//

import Foundation
import CoreMotion

enum SpeedCalculator {
    struct DeviceMotion {
        let x: Double
        let y: Double
        let z: Double
        let roll: Double
        let pitch: Double
    }
    
    /// 3軸成分から水平1軸成分のみを取り出す
    static func calculateHorizontalAcceleration(_ motion: CMDeviceMotion) -> Double {
        // 単位を度数に変換
        let rollDeg = motion.attitude.roll * 180.0 / Double.pi
        let pitchDeg = motion.attitude.pitch * 180.0 / Double.pi
        // -90度から+90度の範囲となるよう正規化
        let roll90: Double
        if (rollDeg > 90.0) { // 傾きが90度を上回っている場合, 超えている分を90から引く
            roll90 = 90.0 - (rollDeg - 90.0)
        } else if (rollDeg < -90) {
            roll90 = -90.0 - (rollDeg + 90.0)
        } else {
            roll90 = rollDeg
        }
        let pitch90 = pitchDeg // pitchは元から-90から+90の範囲になっているのでそのまま
        
        let rollRadian = roll90 / (180.0 / Double.pi)
        let pitchRadian = pitch90 / (180.0 / Double.pi)
        
        let xWeight = cos(rollRadian)
        let yWeight = cos(pitchRadian)
        let zWeight = abs(rollRadian) > abs(pitchRadian) ? abs(sin(rollRadian)) : abs(sin(pitchRadian))
        
        let xHorizontal = motion.userAcceleration.x * xWeight
        let yHorizontal = motion.userAcceleration.y * yWeight
        let zHorizontal = motion.userAcceleration.z * zWeight
        
        // 三平方の定理で水平方向成分を合成する
        let horizontalComponent = sqrt(pow(xHorizontal, 2) +
                                       pow(yHorizontal, 2) +
                                       pow(zHorizontal, 2))
        // 方向を考慮する (z軸方向で考慮)
        return horizontalComponent * (motion.userAcceleration.z > 0 ? 1 : -1)
    }
    
    /// 平滑化フィルタ
    static func smooth(current: Double, previous: Double) -> Double {
        current * 0.2 + previous * 0.8
    }
    
    /// 加速度(acc)を元に現在速度(currentSpeed)からdelta秒後の速度(NextSpeed)を計算する
    static func calculateNextSpeed(currentSpeed: Double, acceleration: Double, delta: Double) -> Double {
        let gravitationalAcceleration = 9.80665
        return  currentSpeed + (acceleration * delta * gravitationalAcceleration)
    }
}

extension SpeedCalculator {
    static func isGpsAvailable(_ speedGps: Double) -> Bool {
        return speedGps != -1
    }
}
