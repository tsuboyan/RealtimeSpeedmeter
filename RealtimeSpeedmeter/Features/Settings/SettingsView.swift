//
//  SettingsView.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/02/12.
//

import SwiftUI

struct SettingsView: View {
    @State private var selection: Int = 0
    @State private var maximumSpeed: Float = 0
    @ObservedObject private(set) var presenter = SettingsPresenter()
    
    var body: some View {
        NavigationView {
            Form {
                Picker(selection: $selection, label: Text("速度の単位")) {
                    ForEach(0 ..< Unit.allCases.count, id: \.self) { num in
                        Text(Unit.allCases[num].name)
                    }
                }.onChange(of: selection) { newValue in
                    presenter.onChangeUnit(Unit(rawValue: newValue)!)
                }
                
                VStack {
                    Text("スピードメーターの最高速度: \(Int(maximumSpeed)) \(presenter.state.unit.name)")
                    HStack {
                        Text("20")
                        Slider(value: Binding(
                            get: { maximumSpeed },
                            set: { newValue in
                                maximumSpeed = newValue
                                presenter.onChangeMaximumSpeed(Int(newValue))
                            }), in: 20...500)
                        Text("500")
                    }
                }
            }
        }
        .onAppear {
            selection = presenter.state.unit.rawValue
            maximumSpeed = Float(presenter.state.maximumSpeed)
        }
    }
}
