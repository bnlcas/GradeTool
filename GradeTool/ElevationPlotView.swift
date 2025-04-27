//
//  ElevationPlotView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 4/17/25.
//

import SwiftUI
import Charts


struct ElevationPlotView: View {
    //@ObservedObject var geoSurvey: GeoSurvey = GeoSurvey()
    //geoSurvey.lines.count > 0
    
    @Binding var data: [SurveyPoint]
    /*= [SurveyPoint(id: 0, distance: 0.0, elevation: 1330.0),
                                      SurveyPoint(id: 1, distance: 100.0, elevation: 1100.0),
                                      SurveyPoint(id: 2, distance: 222.0, elevation: 1250.0),
                                      SurveyPoint(id: 3, distance: 333.0, elevation: 1550.0),
                                      SurveyPoint(id: 4, distance: 444.0, elevation: 1530.0),
                                      SurveyPoint(id: 5, distance: 554.0, elevation: 1532.0),
    ]*/
    let height : CGFloat

    @State private var showGradient = true
    @State private var gradientRange = 0.4
    @State private var chartColor: Color = .red

    private var gradient: Gradient {
        var colors = [chartColor]
        if showGradient {
            colors.append(chartColor.opacity(gradientRange))
        }
        return Gradient(colors: colors)
    }
    
    var body: some View {
        Chart(data, id: \.id) {
            /*AreaMark(
                x: .value("Distance", $0.distance),
                y: .value("Elevation", $0.elevation)
            )
            .foregroundStyle(gradient)
            .interpolationMethod(.linear)
             */
            LineMark(
                x: .value("Distance", $0.distance),
                y: .value("Elevation", $0.elevation)
            )
            //.accessibilityLabel($0.day.formatted(date: .complete, time: .omitted))
            //.accessibilityValue("\($0.sales) (m)")
            .accessibilityHidden(true)//isOverview)
            .lineStyle(StrokeStyle(lineWidth: 2.0))
            .interpolationMethod(.linear)// interpolationMethod.mode)
            .foregroundStyle(chartColor)
        }
        .chartXAxisLabel("Distance (m)")
        .chartYAxisLabel("Elevation (m)")
        //.accessibilityChartDescriptor(self)
        .chartYAxis(.visible)
        .chartXAxis(.visible)
        //.chartXScale(range: [0.0, CGFloat(data.last!.distance)])
        .frame(height: self.height)
    }
}

#Preview {
    ElevationPlotView(data: .constant([SurveyPoint(id: 0, distance: 0.0, elevation: 1330.0),
                                             SurveyPoint(id: 1, distance: 100.0, elevation: 1100.0),
                                             SurveyPoint(id: 2, distance: 222.0, elevation: 1250.0),
                                             SurveyPoint(id: 3, distance: 333.0, elevation: 1550.0),
                                             SurveyPoint(id: 4, distance: 444.0, elevation: 1530.0),
                                             SurveyPoint(id: 5, distance: 554.0, elevation: 532.0),
           ]),  height: 250)
}
