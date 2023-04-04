//
//  SettingsView.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/02/12.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private(set) var presenter = SettingsPresenter()
    
    var body: some View {
        NavigationView {
            Form {
                Picker(selection: Binding(
                    get: { presenter.state.unit.rawValue },
                    set: { newValue in
                        presenter.onChangeUnit(Unit(rawValue: newValue)!)
                    }), label: Text("速度の単位")) {
                        ForEach(0 ..< Unit.allCases.count, id: \.self) { num in
                            Text(Unit.allCases[num].name)
                        }
                    }
                
                VStack {
                    Text("アナログメーターの最高速度: \(Int(presenter.state.maximumSpeed)) \(presenter.state.unit.name)")
                    HStack {
                        Text("\(Int(Constants.maximumSpeedLowerLimit))")
                        Slider(value: Binding(
                            get: { Double(presenter.state.maximumSpeed) },
                            set: { newValue in
                                presenter.onChangeMaximumSpeed(Int(newValue))
                            }), in: (Constants.maximumSpeedLowerLimit...Constants.maximumSpeedUpperLimit),
                               step: Constants.maximumSpeedConfigurableInterval)
                        Text("\(Int(Constants.maximumSpeedUpperLimit))")
                    }
                }
            }
        }
    }
}
