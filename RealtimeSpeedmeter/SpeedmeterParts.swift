//
//  SpeedmeterParts.swift
//  RealtimeSpeedmeter
//
//  Created by Atsushi Otsubo on 2023/01/25.
//

import SwiftUI

struct SpeedmeterParts: View {
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                Triangle()
                    .fill(.blue)
                    .frame(width: 1, height: 1)
                    // .rotationEffect(Angle(degrees: -45), anchor: UnitPoint(x: -0.2, y: 1.0))
                    // .animation(<#T##animation: Animation?##Animation?#>, value: <#T##Equatable#>)
                
            }.frame(width: 200, height: 200)
            Spacer()
        }
                
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: -100))
            path.addLine(to: CGPoint(x: -20, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
            path.closeSubpath()
        }
    }
}

struct SpeedmeterParts_Previews: PreviewProvider {
    static var previews: some View {
        SpeedmeterParts()
    }
}
