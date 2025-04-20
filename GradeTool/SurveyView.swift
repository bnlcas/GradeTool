//
//  SurveyView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 4/5/25.
//

import SwiftUI
import CoreMotion
import CoreLocation

// A helper function to convert a Cartesian point back to spherical coordinates.
func cartesianToSpherical(point: SIMD3<Double>) -> (longitude: Double, latitude: Double, altitude: Double) {
    let earthRadius = 6371000.0
    let x = point.x, y = point.y, z = point.z
    let r = sqrt(x * x + y * y + z * z)
    let lat = asin(z / r) * 180.0 / .pi
    let lon = atan2(y, x) * 180.0 / .pi
    let alt = r - earthRadius
    return (lon, lat, alt)
}

struct SurveyView: View {
    @ObservedObject var geoSurvey: GeoSurvey// = GeoSurvey()
    
    @Environment(\.presentationMode) var presentationMode
    
    let addPoint: () -> Void
    
    var body: some View {
        VStack{
            HStack(alignment: .top) {
                Text("Survey:")
                    .font(.title)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            ElevationPlotView(height: 250)
            HStack{
                Button(action: {
                    geoSurvey.clearSurvey()
                    print("clear count: \(geoSurvey.lines.count)")
                    addPoint()
                    print("clear count: \(geoSurvey.lines.count)")
                })
                {
                    HStack{
                        Text("New Survey")
                        Image(systemName: "trash")
                    }
                }
                .padding()
                Spacer()
            }
            ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(geoSurvey.lines.indices, id: \.self) { index in
                            SurveyPointView(line: geoSurvey.lines[index], index: index, deletePoint: {ind in deletePoints(at: IndexSet(integer: ind))})
                        }
                        .onDelete(perform: deletePoints)
                        .onMove(perform: movePoints)
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
        }
    }
    
    func deletePoints(at offsets: IndexSet) {
        geoSurvey.lines.remove(atOffsets: offsets)
    }

    
    func movePoints(from source: IndexSet, to destination: Int) {
        geoSurvey.lines.move(fromOffsets: source, toOffset: destination)
    }
}

struct SurveyPointView: View {
    var line: Line3D
    
    let index: Int
    
    let deletePoint: (Int) -> Void
    
    var body: some View {
        let (lon, lat, alt) = cartesianToSpherical(point: line.point.vector)
        HStack {
            Text("Lat: \(String(format: "%.3f", lat))°, Long: \(String(format: "%.3f", lon))°")
            Text("Alt: \(String(format: "%.0f", alt)) (m)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { deletePoint(index) }){
                Image(systemName: "trash")
            }
        }
    }
}

#Preview {
    SurveyView(geoSurvey: GeoSurvey(), addPoint: {})//geoSurvey: GeoSurvey())
}
