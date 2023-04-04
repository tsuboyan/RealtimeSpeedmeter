//
//  Constants.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/04/04.
//

enum Constants {
    // MARK: - Speed Measurement Param
    static let fps: Double = 100
    /// この加速度以下の状態が stoppingResetInterval 秒間続くと速度をリセットする(ドリフト防止)
    static let stoppingStdevThresh = 0.01
    static let stoppingResetInterval = 1.0
    /// 標準偏差による停止判定用の配列の要素数
    static let stoppingAccelerationsCapacity = 10
    
    // MARK: - Settings Param
    static let defaultMaximumSpeed = 30
    static let maximumSpeedUpperLimit: Double = 500
    static let maximumSpeedLowerLimit: Double = 20
    static let maximumSpeedConfigurableInterval: Double = 10
}
