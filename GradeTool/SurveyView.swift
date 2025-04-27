//
//  SurveyView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 4/5/25.
//

import SwiftUI
import CoreMotion
import CoreLocation
import UniformTypeIdentifiers



func exportLinesCSV(_ lines: [Line3D]) -> URL? {
    // CSV header
    let header = "point_id,point_x,point_y,point_z,direction_x,direction_y,direction_z"
    var csv = header + "\n"
    
    // One row per Line3D
    for line in lines {
        let px = line.point.x
        let py = line.point.y
        let pz = line.point.z
        let dx = line.direction.x
        let dy = line.direction.y
        let dz = line.direction.z
        
        let row = [
            line.id.uuidString,
            String(px), String(py), String(pz),
            String(dx), String(dy), String(dz)
        ].joined(separator: ",")
        
        csv += row + "\n"
    }
    
    // Write to a temp file
    let filename = "Lines3D_\(Date().timeIntervalSince1970).csv"
    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    
    do {
        try csv.data(using: .utf8)?.write(to: tmpURL)
        return tmpURL
    } catch {
        print("Failed to write CSV:", error)
        return nil
    }
}

struct LinesCSVFile: Transferable {
    let lines: [Line3D]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { item in
            // generate the CSV on‐demand
            guard let csv_url = exportLinesCSV(item.lines) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return SentTransferredFile(csv_url)

            // wrap it in a SentTransferredFile
        }
    }
}

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
    
    let addPoint: () -> Void
    
    var body: some View {
        VStack{
            HStack(alignment: .top) {
                Text("Survey:")
                    .font(.title)
                Spacer()
            }
            .padding()
                ElevationPlotView(data: $geoSurvey.surveyPoints, height: 250)
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
                ShareLink(
                            item: LinesCSVFile(lines: geoSurvey.lines),
                                preview: SharePreview(
                                  "Survey Lines CSV",
                                  icon: Image(systemName: "doc.text")
                                )
                            ) {
                                Label("Export Points", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                            }
                            .disabled(geoSurvey.lines.isEmpty)
            }
            /*
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
             */
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
