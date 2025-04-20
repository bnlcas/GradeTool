//
//  ElevationPlotView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 4/17/25.
//

import SwiftUI

struct ElevationPlotView: View {
    //@ObservedObject var geoSurvey: GeoSurvey = GeoSurvey()
    //geoSurvey.lines.count > 0
    let height : CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            if(1 > 0){
                
                Path { path in
                    let x_origin = geometry.size.width * 0.1
                    let y_origin = geometry.size.height * 0.9

                    let x_end = geometry.size.width * 0.9
                    let y_end = geometry.size.height * 0.9
                    
                    let x0 = geometry.size.width * 0.1
                    let y0 = geometry.size.height * 0.8
                    
                    let x1 = geometry.size.width * 0.3
                    let x2 = geometry.size.width * 0.5
                    let x3 = geometry.size.width * 0.7
                    let x4 = geometry.size.width * 0.9
                    
                    let y1 = geometry.size.height * 0.4
                    let y2 = geometry.size.height * 0.7
                    let y3 = geometry.size.height * 0.1
                    let y4 = geometry.size.height * 0.2
                    
                    path.move(to: CGPoint(x: x_origin, y: y_origin))
                    
                    path.addLines([
                        CGPoint(x: x0, y: y0),
                        CGPoint(x: x1, y: y1),
                        CGPoint(x: x2, y: y2),
                        CGPoint(x: x3, y: y3),
                        CGPoint(x: x4, y: y4),
                        CGPoint(x: x_end, y: y_end),
                        CGPoint(x: x_origin, y: y_origin)
                    ])
                }
                .fill(Gradient(colors: [.red, .red, .black]))
            }
        }
        .frame(width: 400, height: self.height)
    }
}

#Preview {
    ElevationPlotView(height: 250)
}
