//
//  ReticleView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 9/8/24.
//

import SwiftUI

struct ReticleView: View {
    let thickness : CGFloat = 2.0
    
    let centerRadius : CGFloat = 8.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                Path{ path in
                    let center_X = geometry.size.width * 0.5
                    
                    let center_Y = geometry.size.height * 0.5
                    let reticle_width = geometry.size.width * 0.25
                    
                    path.move(to: CGPoint(x: center_X - reticle_width, y: center_Y))
                    path.addLine(to: CGPoint(x: center_X - centerRadius, y: center_Y))
                    
                    path.move(to: CGPoint(x: center_X + reticle_width, y: center_Y))
                    path.addLine(to: CGPoint(x: center_X + centerRadius, y: center_Y))
                    
                    
                    path.move(to: CGPoint(x: center_X, y: center_Y - reticle_width))
                    path.addLine(to: CGPoint(x: center_X, y: center_Y - centerRadius))
                    
                    path.move(to: CGPoint(x: center_X, y: center_Y + reticle_width))
                    path.addLine(to: CGPoint(x: center_X, y: center_Y + centerRadius))
                    
                    
                    path.move(to: CGPoint(x: center_X + centerRadius, y: center_Y))
                    path.addArc(center: CGPoint(x: center_X, y: center_Y), radius:centerRadius, startAngle: Angle(degrees: 0.0), endAngle: Angle(degrees: 360), clockwise: true)
                }
                .fill(.clear)
                .stroke(.white, lineWidth: thickness)
                Path{ path in
                    let center_X = geometry.size.width * 0.5
                    
                    let center_Y = geometry.size.height * 0.5
                    
                    path.move(to: CGPoint(x: center_X - centerRadius, y: center_Y))
                    path.addLine(to: CGPoint(x: center_X + centerRadius, y: center_Y))
                    path.move(to: CGPoint(x: center_X, y: center_Y - centerRadius))
                    path.addLine(to: CGPoint(x: center_X, y: center_Y + centerRadius))
                }
                .fill(.clear)
                .stroke(.white, lineWidth: 1.0)
            }
        }
    }
}

#Preview {
    ZStack{
        Rectangle().fill(.gray)
        ReticleView()
    }
}
