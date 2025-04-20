//
//  ContentView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 1/14/24.
//

import SwiftUI
import CoreMotion
import SensorKit
//import CameraView

enum GradeUnits: String, CaseIterable, Identifiable {
    case degrees
    case percentGrade
    var id: String { self.rawValue }
}

enum InstrumentMode {
    case level
    case camera
}

struct ContentView: View {
    let motionManager = CMMotionManager();
    let queue = OperationQueue()

    @StateObject private var locationManager = LocationManager()
    
    let previewHeight : CGFloat = 400
    
    @State var grade : Double?
    @State var gradeAngle: Double?
    @State var horizontalAngle : Double = 0.0
        
    @AppStorage("cameraLevel") var cameraBasedLevel = false
        
    @State var hasPassedDebounceThreshold = true
    
    @AppStorage("gradeUnits") private var gradeUnitsRawValue: String = GradeUnits.percentGrade.rawValue

    // A computed property that converts the raw value to our enum.
    @State var gradeUnits : GradeUnits = .percentGrade
    
    /*GradeUnits {
        get {
            GradeUnits(rawValue: gradeUnitsRawValue) ?? .percentGrade
        }
        set {
            gradeUnitsRawValue = newValue.rawValue
        }
    }*/
        
    let debounceThresholdGrade = 1.0
    
    @State private var showSurveyView = false
    
    @State private var currentAttitude: CMAttitude? = nil
    
    @StateObject var geoSurvey: GeoSurvey = GeoSurvey()

    func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func gravityForwardAngle(rotationMatrix : CMRotationMatrix, gravity: CMAcceleration) -> Double{
        //forward vector3: [0,0,1]
        //normalized gravity vector: [0,0,1]
        let forwardRotated = CMAcceleration(x: rotationMatrix.m13, y: rotationMatrix.m23, z: rotationMatrix.m33)
        //let dot = forwardRotated.x * gravity.x + forwardRotated.y * gravity.y + forwardRotated.z * gravity.z//gravity is 0,0,9.8 - needs norming...
        let dot = forwardRotated.z
        let theta = acos(dot) - 1.5707963267948966
        return theta
    }
    
    func addSurveyPoint() {
        guard let location = locationManager.location, let attitude = self.currentAttitude else {
            print("Location or Attitude not available.")
            return
        }
        geoSurvey.addSurveyPoint(latitude: location.coordinate.latitude,
                                 longitude: location.coordinate.longitude,
                                 elevation: location.altitude,
                                 attitude: attitude)
    }
    
    func deleteSurveyPoints(at offsets: IndexSet) {
        geoSurvey.lines.remove(atOffsets: offsets)
    }
    
    
    var body: some View {
        VStack {
            HStack{
                Image(systemName: "righttriangle")
                Text("Grade:")
                Spacer()
            }
            if(grade != nil) {
                HStack{
                    switch(gradeUnits){
                    case .degrees:
                        Text(String(format: "%.2f", abs(gradeAngle!)) + "°")
                            .frame(width: 80, height:25)
                    case .percentGrade:
                        Text(String(format: "%.2f", abs(grade!)) + "%")
                            .frame(width: 80, height:25)
                    }

                    //Text("\((10.0 * grade).rounded()/10.0) %")
                    if(cameraBasedLevel){
                        SlopeVisualizerView(height: 25, grade: $grade)
                            .frame(width: 30, height:25)
                            .transition(.scale(scale: 0.0, anchor: UnitPoint(x: 0.5, y: 1.0)))
                        
                    }
                    Spacer()
                }
                GeometryReader { geometry in
                    // Calculate full screen width and height as 4/3 of the width.
                    if(cameraBasedLevel){
                        //CameraFeedTargetingView()
                        
                        ZStack{
                            CameraFeedTargetingView()
                            ReticleView()
                        }
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .transition(.move(edge: .leading))
                        
                    } else{
                        SlopeVisualizerView(height: previewHeight, grade: $grade)
                            .transition(.move(edge: .trailing))
                        //.transition(.scale(scale: 0.0, anchor: UnitPoint(x: 0.1, y: 0.0)))
                        
                    }
                }
            } else{
                Spacer()
                Text("Initializing...")
                ProgressView()
                Spacer()
            }
            if(locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse) {
                if let location = locationManager.location {
                    // Display latitude, longitude, and elevation (altitude)
                    HStack(alignment: .top){
                        VStack(alignment: .leading){
                            HStack{
                                Text(String(format: "Latitude: %.3f°,", location.coordinate.latitude))
                                
                                Text(String(format: "Longitude: %.3f°",
                                            location.coordinate.longitude))
                            }
                            Text(String(format: "Elevation: %.1f (m)",
                                        location.altitude))
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    Text("Getting location...")
                }
                HStack{
                    VStack(alignment: .leading) {
                        Text("Total Path Distance: \(String(format: "%.1f", geoSurvey.surveyDistance)) (m)")
                        Text("Elevation Gain: \(String(format: "%.1f", geoSurvey.surveyElevation)) (m)")
                        Text("Target Elevation: \(String(format: "%.1f", geoSurvey.targetPointElevation)) (m)")
                    }
                    Spacer()
                }
                .padding()
                HStack {
                    Button(action: {
                        withAnimation(Animation.linear(duration: 0.4)){
                            self.showSurveyView = true
                        }
                    }){
                        HStack{
                            Text("Survey Plot")
                            Image(systemName: "map.circle")
                        }
                    }
                    .padding()
                    Spacer()
                    Button(action: {
                        addSurveyPoint()
                    }){
                        HStack{
                            Text("Add Point")
                            Image(systemName: "mappin.and.ellipse.circle")
                        }
                        //.background(.blue)
                        //.foregroundColor(Color.white)
                    }
                    .padding()
                }
            } else{
                Text("Geolocation Unavailable")
                Spacer()
            }

            
            /*
            HStack{
                Text("Grade Viewer:")
                Spacer()
                Button(action: {
                    withAnimation(Animation.linear(duration: 0.4)){
                        self.cameraBasedLevel.toggle()
                    }
                }){
                    HStack{
                        if(self.cameraBasedLevel){
                            Text("Plane")
                            Image(systemName: "righttriangle.fill")
                        } else {
                            Text("Camera")
                            Image(systemName: "camera")
                        }
                    }
                }
            }
            .padding()*/
            Picker("Units:", selection: $cameraBasedLevel) {
                HStack{
                    Text("Camera Level")
                    //Image(systemName: "camera")
                }
                .tag(true)
                HStack{
                    Text("Device Level")
                    //Image(systemName: "righttriangle.fill")
                }
                .tag(false)
            }
            .frame(height:48)
            .pickerStyle(SegmentedPickerStyle())
            
            Picker("Units:", selection: $gradeUnits) {
                Text("Percent Grade").tag(GradeUnits.percentGrade)
                Text("Degrees").tag(GradeUnits.degrees)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(5.0)
        .onAppear {
            self.motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical,  to: self.queue) { (data: CMDeviceMotion?, error: Error?) in
                guard let data = data else {
                    print("Error: \(error!)")
                    return
                }
                
                let attitude: CMAttitude = data.attitude
                
                DispatchQueue.main.async {
                    currentAttitude = attitude  // Save current attitude for survey points.
                    let theta : Double
                    if(self.cameraBasedLevel){
                        
                        //horizontalAngle =  (attitude.pitch - 1.5707963267948966)
                        
                        //sign(attitude.yaw) *
                        //theta = horizontalAngle
                        theta = gravityForwardAngle(rotationMatrix: attitude.rotationMatrix, gravity: data.gravity)
                    } else{
                        theta = attitude.pitch
                    }
                    //let theta
                    //acos(gravity_z_normed_dot)
                    let newGrade = 100 * tan(theta)
                    
                    if(sign(newGrade) != sign(grade ?? 0.0) && hasPassedDebounceThreshold)
                    {
                        hapticFeedback()
                        hasPassedDebounceThreshold = false
                        
                    }
                    hasPassedDebounceThreshold = hasPassedDebounceThreshold || abs(newGrade) > debounceThresholdGrade
                    
                    grade = newGrade
                    gradeAngle = theta * 57.29577951308232
                }
            }
        }
        .sheet(isPresented: $showSurveyView) {
            // Pass the current location and attitude into SurveyView.
            SurveyView(geoSurvey: geoSurvey, addPoint: { addSurveyPoint() })
                .presentationDetents([.fraction(0.6)])

        }
    }

}

#Preview {
    ContentView()
}
