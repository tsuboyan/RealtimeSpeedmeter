//
//  SpeedmeterView.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/23.
//

import SwiftUI

struct SpeedmeterView: View {
    @StateObject private var state: SpeedmeterViewState
    let presenter: SpeedmeterPresenter
    
    init() {
        let state = SpeedmeterViewState()
        self._state = StateObject(wrappedValue: state)
        presenter = SpeedmeterPresenter(state: state)
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: 32)
            HStack {
                VStack {
                    Gauge(value: state.speedAccKiloMeter, in: 0...20) {} currentValueLabel: {
                        Text("\(String(format: "%.1f", state.speedAccKiloMeter))")
                    }.gaugeStyle(SpeedometerGaugeStyle(unit: "KM/H"))
                    Text("速度 (ACC)")
                }
                Spacer()
                VStack {
                    Gauge(value: abs(state.acc), in: 0...1) {} currentValueLabel: {
                        Text("\(String(format: "%.2f", state.acc))")
                    }.gaugeStyle(SpeedometerGaugeStyle(unit: "ACC"))
                    Text("加速度")
                }
            }
            .padding()
            HStack {
                VStack {
                    Gauge(value: state.speedGpsKiloMeter, in: 0...20) {} currentValueLabel: {
                        Text("\(String(format: "%.1f", state.speedGpsKiloMeter))")
                    }.gaugeStyle(SpeedometerGaugeStyle(unit: "KM/H"))
                    Text("速度 (GPS)")
                }
                Spacer()
            }
            .padding()
            if state.stopping { Text("停止中") }
            Spacer()
            HStack {
                Button("Start", action: {
                    presenter.onTapStart()
                }).buttonStyle(.borderedProminent)
                Spacer().frame(width: 20)
                Button("Stop", action: {
                    presenter.onTapStop()
                }).buttonStyle(.borderedProminent)
                Button("Reset", action: {
                    presenter.onTapReset()
                }).buttonStyle(.borderedProminent)
            }
            Spacer().frame(height: 32)
        }
        .padding()
        .onAppear {
            presenter.onAppear()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedmeterView()
    }
}
