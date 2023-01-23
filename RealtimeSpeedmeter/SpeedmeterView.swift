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
            HStack {
                Text("acceleration Y: ")
                Text("\(state.accelerationY)")
            }
            HStack {
                Text("speed Y: ") 
                Text("\(state.speedYKM * 100)")
            }
            HStack {
                Button("Start", action: {
                    presenter.onTapStart()
                }).buttonStyle(.borderedProminent)
                Spacer().frame(width: 20)
                Button("Stop", action: {
                    presenter.onTapStop()
                }).buttonStyle(.borderedProminent)
            }
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
