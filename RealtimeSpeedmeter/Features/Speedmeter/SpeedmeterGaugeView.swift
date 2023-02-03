//
//  GaugePlayground.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/28.
//

import SwiftUI

struct SpeedmeterGaugeView: View {
    @State private var currentSpeed = 80.0
 
    var body: some View {
        VStack {
            Spacer().frame(height: 20)
        
        Gauge(value: currentSpeed, in: 0...100) {
//            Image(systemName: "gauge.medium")
//                .font(.system(size: 50.0))
        } currentValueLabel: {
            Text("\(currentSpeed.formatted(.number))")
        }
        .gaugeStyle(SpeedometerGaugeStyle(unit: "KM/H"))
            Spacer()
        }
    }
}

struct SpeedometerGaugeStyle: GaugeStyle {
    private let unit: String
    init(unit: String) {
        self.unit = unit
    }
    
    private var leafGreenGradient = LinearGradient(gradient: Gradient(colors: [ Color(red: 85/255, green: 160/255, blue: 57/255), Color(red: 181/255, green: 216/255, blue: 65/255) ]), startPoint: .trailing, endPoint: .leading)
 
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
 
            Circle()
                .foregroundColor(Color(.systemGray6))
 
            Circle()
                .trim(from: 0, to: 0.75 * configuration.value)
                .stroke(leafGreenGradient, lineWidth: 20)
                .rotationEffect(.degrees(135))
 
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.black, style: StrokeStyle(lineWidth: 10, lineCap: .butt, lineJoin: .round, dash: [1, 34], dashPhase: 0.0))
                .rotationEffect(.degrees(135))
 
            VStack {
                configuration.currentValueLabel
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                Text(unit)
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.gray)
            }
 
        }
        .frame(width: 150, height: 150)
 
    }
}

struct SpeedmeterGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedmeterGaugeView()
    }
}
