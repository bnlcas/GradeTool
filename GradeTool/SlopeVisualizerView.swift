//
//  SlopeVisualizerView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 9/8/24.
//

import SwiftUI

struct SlopeVisualizerView: View {
    let height : CGFloat
    
    @Binding var grade : Double?

    var body: some View {
        GeometryReader { geometry in
            if(grade != nil){
                
                Path { path in
                    let width = geometry.size.width
                    
                    let center_y = 0.7*self.height
                    
                    let top_pt = center_y - width * grade! / 100
                    
                    let top_pt_clamp = max(min(height, top_pt), 0.0)
                    
                    let intersect_y : CGFloat
                    let intersect_x : CGFloat
                    if(top_pt != top_pt_clamp)
                    {
                        intersect_x = -(top_pt_clamp - center_y) * 100 / grade!
                        intersect_y = top_pt_clamp
                        
                    } else {
                        intersect_x = width
                        intersect_y = top_pt
                    }
                    
                    
                    path.move(to: CGPoint(x: 0, y: center_y))
                    
                    path.addLines([
                        CGPoint(x: intersect_x, y: intersect_y),
                        CGPoint(x:width, y: top_pt_clamp),
                        CGPoint(x: width, y: center_y),
                        CGPoint(x:0, y: center_y)
                        
                    ])
                }
                .fill(.red)
            }
        }
        .frame(height: self.height)
    }
}

#Preview {
    SlopeVisualizerView(height: 500, grade: .constant(50.0))
}
