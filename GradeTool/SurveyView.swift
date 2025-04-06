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
        NavigationView {
            VStack {
                ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(geoSurvey.lines.indices, id: \.self) { index in
                                SurveyPointView(line: geoSurvey.lines[index])
                            }
                            .onDelete(perform: deletePoints)
                            .onMove(perform: movePoints)
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 200)
                HStack {
                    Button("Add Survey Point") {
                        addSurveyPoint()
                    }
                    .padding()
                    Spacer()
                    Button("Clear All") {
                        geoSurvey.clearSurvey()
                    }
                    .padding()
                }
                
                VStack(alignment: .leading) {
                    if geoSurvey.lines.count > 1 {
                        let odometer = geoSurvey.surveyPathOdometer()
                        let elevation = geoSurvey.surveyPathElevationGain()

                        Text("Total Distance: \(String(format: "%.2f", odometer)) m")
                        Text("Elevation Gain: \(String(format: "%.2f", elevation)) m")
                        HStack{
                            Text("Total Distance:")
                            Spacer()
                            Text("\(String(format: "%.2f", odometer)) (m)")
                        }
                        HStack{
                            Text("Total Elevation:")
                            Spacer()
                            Text("\(String(format: "%.2f", geoSurvey.targetPointElevation)) (m)")
                        }
                    } else {
                        Text("Add more survey points to calculate stats.")
                    }
                }
                .padding()
            }
            .navigationTitle("Survey")
            .toolbar {
                /*ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }*/
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
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
    
    var body: some View {
        let (lon, lat, alt) = cartesianToSpherical(point: line.point)
        HStack {
            Text("Lat: \(String(format: "%.2f", lat))°, Long: \(String(format: "%.2f", lon))°")
            Text("Alt: \(String(format: "%.0f", alt)) (m)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SurveyView()
}
