//
//  SpeedmeterView.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/23.
//

import SwiftUI

struct SpeedmeterView: View {
    @ObservedObject private(set) var presenter: SpeedmeterPresenter
    
    init() {
        presenter = SpeedmeterPresenter()
    }
    
    var body: some View {
        
        let width = UIScreen.main.bounds.width
        
        let contents = VStack {
            #if DEBUG
                HStack {
                    Button {
                        presenter.onTapStartStop()
                    } label: {
                        Text(presenter.state.isSensorActive ? "ストップ" : "スタート")
                    }
                    .buttonStyle(.bordered)
                }
                Spacer().frame(height: 32)
            #endif
            Spacer().frame(height: 32)
            ZStack {
                VStack {
                    Spacer()
                    HStack {
                        Text("0")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(presenter.state.maximumSpeed)")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(.gray)
                            
                    }
                }.frame(width: width - 80, height: width - 80, alignment: .bottom)
                SpeedmeterGaugeView(maximumSpeed: Double(presenter.state.maximumSpeed),
                                    currentSpeed: presenter.state.accelerationSpeed,
                                    unitName: presenter.state.unit.name,
                                    reset: { presenter.onTapReset() })
                .padding()
            }
            
            
            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    Text("加速度")
                        .bold()
                        .font(.title3)
                    Text(String(format: "%.2f G", presenter.state.acceleration))
                        .font(.body)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2)))
                VStack(spacing: 8) {
                    Text("計測方法")
                        .bold()
                        .font(.title3)
                    Text(presenter.state.measurementMethod)
                        .font(.body)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2)))
            }
            Spacer()
        }
            .padding()
            .onAppear {
                presenter.onAppear()
            }
        
        return NavigationView {
            contents
        }.navigationBarTitle("RealtimeSpeedmeter", displayMode: .inline)
            .navigationBarItems(
                trailing: NavigationLink(destination: SettingsView().navigationTitle("Settings")) {
                    Image(systemName: "gearshape.fill")
                })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedmeterView()
        SpeedmeterGaugeView(maximumSpeed: 100, currentSpeed: 1, unitName: "km/h")
            .padding()
    }
}
