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
                        presenter.onChange(unit: Unit(rawValue: newValue)!)
                    }), label: Text("unit_title")) {
                        ForEach(0 ..< Unit.allCases.count, id: \.self) { num in
                            Text(Unit.allCases[num].name)
                        }
                    }
                
                VStack {
                    HStack {
                        Text("speedmeter_upper_limit_title")
                        Spacer()
                        Text("\(Int(presenter.state.maximumSpeed)) \(presenter.state.unit.name)")
                    }
                    HStack {
                        Text("\(Int(Constants.maximumSpeedLowerLimit))")
                        Slider(value: Binding(
                            get: { Double(presenter.state.maximumSpeed) },
                            set: { newValue in
                                presenter.onChange(maximumSpeed: Int(newValue))
                            }), in: (Constants.maximumSpeedLowerLimit...Constants.maximumSpeedUpperLimit),
                               step: Constants.maximumSpeedConfigurableInterval)
                        Text("\(Int(Constants.maximumSpeedUpperLimit))")
                    }
                }
                
                Picker(selection: Binding(
                    get: { presenter.state.colorTheme.rawValue },
                    set: { newValue in
                        presenter.onChange(colorTheme: ColorTheme(rawValue: newValue)!)
                        
                    }), label: Text("theme_title")) {
                        ForEach(0 ..< ColorTheme.allCases.count, id: \.self) { num in
                            Text(ColorTheme.allCases[num].name)
                        }
                    }
            }
        }
    }
}
