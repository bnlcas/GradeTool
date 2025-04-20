//
//  GeoSurvey.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 4/5/25.
//

//import Foundation
import simd
import CoreMotion

struct SIMD3Double: Codable {
    var x: Double
    var y: Double
    var z: Double

    init(_ vector: SIMD3<Double>) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }

    var vector: SIMD3<Double> {
        return SIMD3<Double>(x, y, z)
    }
}

struct Line3D: Codable, Identifiable {
    var id: UUID = UUID()
    var point: SIMD3Double
    var direction: SIMD3Double
}

class GeoSurvey: ObservableObject {
    @Published var lines: [Line3D] = [] {
        didSet {
            saveLines()
            updateSurveyStats()
        }
    }
    
    @Published var surveyDistance: Double = 0.0
    @Published var surveyElevation: Double = 0.0
    @Published var targetPointElevation: Double = 0.0
    
    var deviceLevelForward = true
    /*
        Line3D(point: SIMD3<Double>(0, 0, 0), direction: SIMD3<Double>(1, 1, 0)),
        Line3D(point: SIMD3<Double>(1, 0, 0), direction: SIMD3<Double>(0, 1, 1)),
        Line3D(point: SIMD3<Double>(0, 1, 0), direction: SIMD3<Double>(1, 0, 1))
    ]*/
    
    init() {
        loadLines()
        updateSurveyStats()
    }
    
    private func saveLines() {
        if let data = try? JSONEncoder().encode(lines) {
            UserDefaults.standard.set(data, forKey: "GeoSurveyLines")
        }
    }
    
    private func loadLines() {
        if let data = UserDefaults.standard.data(forKey:  "GeoSurveyLines"),
           let decodedLines = try? JSONDecoder().decode([Line3D].self, from: data) {
            lines = decodedLines
        }
    }
    
    func updateSurveyStats(){
        if(self.lines.count > 1){
            surveyDistance = surveyPathOdometer()
            //print("survey distance: \(surveyDistance) (m?)")

            surveyElevation = surveyPathElevationGain()
            //print("survey distance: \(surveyElevation) (m?)")
            
            if let intersectionPoint = leastSquaresIntersection(of: self.lines) {
                let (longitude, latitude, altitude) = cartesianToSpherical(point: intersectionPoint)
                //print("Least-squares intersection point: \(intersectionPoint)")
                //print("long: \(longitude), lag: \(latitude), elevation: \(altitude)")
                
                targetPointElevation = altitude
            } else {
                targetPointElevation = 0.0
            }
        } else{
            surveyDistance = 0.0
            surveyElevation = 0.0
            targetPointElevation = 0.0
        }
    }
    
    func addSurveyPoint(latitude: Double, longitude: Double, elevation: Double, attitude: CMAttitude) {
        let point = coordinateToSIMD3(longitude: longitude, latitude: latitude, elevation: elevation)
        let direction = deviceAttitudeToDirectionVector(attitude: attitude)
        
        print("device direction: \(direction)")
        lines.append(Line3D(point: SIMD3Double(point), direction: SIMD3Double(direction)))

        updateSurveyStats()
    }
    
    func clearSurvey(){
        lines = []
        updateSurveyStats()
    }

    
    func outerProduct(_ u: SIMD3<Double>) -> simd_double3x3 {
        return simd_double3x3(rows: [
            u * u.x,
            u * u.y,
            u * u.z
        ])
    }
    
    func surveyPathOdometer() -> simd_double1 {
        var pathLength = simd_double1(0.0)
        //pathLength += simd_distance(lines[0].point, lines.last!.point)
        for i in 0..<(lines.count - 1) {
            pathLength += simd_distance(lines[i].point.vector, lines[i+1].point.vector)
        }
        return pathLength
    }
    
    func surveyPathElevationGain() -> simd_double1 {
        let (_, _, altitude0) = cartesianToSpherical(point: lines[0].point.vector)
        let (_, _, altitude1) = cartesianToSpherical(point: lines.last!.point.vector)
        return altitude1 - altitude0
    }
        
    func leastSquaresIntersection(of lines: [Line3D]) -> SIMD3<Double>? {
        guard !lines.isEmpty else { return nil }
        
        var A = simd_double3x3(0) // Accumulate the projection matrices
        var b = SIMD3<Double>(repeating: 0) // Accumulate the projected points
        
        for line in lines {
            // Normalize the direction vector (if not already normalized)
            let u = simd_normalize(line.direction.vector)
            
            // Projection matrix onto the plane perpendicular to u: P = I - u * u^T
            let P = matrix_identity_double3x3 - outerProduct(u)
            
            A += P
            b += P * line.point.vector
        }
        
        // Check that A is invertible by testing its determinant.
        let det = A.determinant// simd.determinant(A)
        if abs(det) < 1e-10 {
            // The configuration is degenerate; an intersection point cannot be determined.
            return nil
        }
        
        // Solve A * z = b for z.
        let z = A.inverse * b
        return z
    }
    
    func coordinateToSIMD3(longitude: Double, latitude: Double, elevation: Double) -> SIMD3<Double> {
        // Earth's mean radius in meters (approximation)
        let earthRadius = 6378137.0//equator
        //6356752.0//Polar
        
        // Convert degrees to radians.
        let latRad = latitude * .pi / 180.0
        let lonRad = longitude * .pi / 180.0
        
        // r is the distance from the Earth's center to the point.
        let r = earthRadius + elevation
        
        // Convert spherical coordinates to Cartesian.
        // x: points toward the prime meridian (0° longitude),
        // y: points toward 90° east,
        // z: points toward the north pole.
        let x = r * cos(latRad) * cos(lonRad)
        let y = r * cos(latRad) * sin(lonRad)
        let z = r * sin(latRad)
        
        return SIMD3<Double>(x, y, z)
    }

    func deviceAttitudeToDirectionVector(attitude: CMAttitude) -> SIMD3<Double> {
        // Define the device's forward vector in its local coordinate system.
        // Here we assume the forward direction (e.g. for the camera) is along -Z.
        let deviceForward = SIMD3<Double>(0, 0, -1)
        
        // Convert the CoreMotion rotation matrix into a simd_double3x3.
        let m = attitude.rotationMatrix
        let rotationMatrix = simd_double3x3(
            SIMD3<Double>(m.m11, m.m12, m.m13),
            SIMD3<Double>(m.m21, m.m22, m.m23),
            SIMD3<Double>(m.m31, m.m32, m.m33)
        )
        // Apply the rotation to the device's forward vector.
        let earthDirection = rotationMatrix * deviceForward
        
        // Normalize the result to obtain a unit direction vector.
        return simd_normalize(earthDirection)
    }
    
    func cartesianToSpherical(point: SIMD3<Double>) -> (longitude: Double, latitude: Double, altitude: Double) {
        // Earth's mean radius in meters (approximation)
        let earthRadius = 6371000.0
        
        // Unpack the Cartesian coordinate components.
        let x = point.x
        let y = point.y
        let z = point.z
        
        // Compute the radial distance from the center of the Earth.
        let r = sqrt(x * x + y * y + z * z)
        
        // Compute latitude and longitude in radians.
        // Latitude: arcsin(z / r)
        let latRad = asin(z / r)
        // Longitude: atan2(y, x)
        let lonRad = atan2(y, x)
        
        // Altitude is the difference between r and Earth's radius.
        let altitude = r - earthRadius
        
        // Convert radians to degrees.
        let latitude = latRad * 180.0 / .pi
        let longitude = lonRad * 180.0 / .pi
        
        return (longitude, latitude, altitude)
    }
}
