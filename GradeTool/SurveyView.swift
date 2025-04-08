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
    @StateObject var geoSurvey: GeoSurvey = GeoSurvey()
    
    // These values can be passed in from ContentView (e.g. current location and attitude).
    var currentLocation: CLLocation?
    var currentAttitude: CMAttitude?
    
    @Environment(\.presentationMode) var presentationMode
    
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
            HStack{
                VStack(alignment: .leading) {
                    Text("Total Path Distance: \(String(format: "%.2f", geoSurvey.surveyDistance)) m")
                    Text("Elevation Gain: \(String(format: "%.2f", geoSurvey.surveyElevation)) m")
                    Text("Target Elevation \(String(format: "%.2f", geoSurvey.targetPointElevation)) (m)")
                }
                Spacer()
            }
            .padding()
            HStack {
                Button("Add Survey Point") {
                    addSurveyPoint()
                }
                .padding()
                Spacer()
                Button("Clear All") {
                    geoSurvey.clearSurvey()
                    deletePoints(at: IndexSet(0..<geoSurvey.lines.count))
                }
                .padding()
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
    
    func addSurveyPoint() {
        guard let location = currentLocation, let attitude = currentAttitude else {
            print("Location or Attitude not available.")
            return
        }
        geoSurvey.addSurveyPoint(latitude: location.coordinate.latitude,
                                 longitude: location.coordinate.longitude,
                                 elevation: location.altitude,
                                 attitude: attitude)
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
            Text("Lat: \(String(format: "%.2f", lat))°, Long: \(String(format: "%.2f", lon))°")
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
    SurveyView()
}
