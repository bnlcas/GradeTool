//
//  ContentView.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 1/14/24.
//

import SwiftUI
import CoreMotion
import SensorKit
import CameraView

enum GradeUnits{
    case degrees
    case percentGrade
}

enum InstrumentMode {
    case level
    case camera
}

struct ContentView: View {
    let motionManager = CMMotionManager();
    let queue = OperationQueue()

    let altimeter = CMAltimeter();
    let altitudeQueue = OperationQueue()
    
    //let locationManager = CLLocationManager()
    
    //let barometer = SRSensorReader(sensor: SRSensor(rawValue: "ambientPressure"))
    //let barometerQueue = OperationQueue()
    
    @StateObject private var sensorKitManager = SensorManager()

    @StateObject private var locationManager = LocationManager()
    
    let previewHeight : CGFloat = 400
    
    @State var grade : Double?
    @State var horizontalAngle : Double = 0.0
        
    @State var cameraBasedLevel = false
    
    @State var elevation : Double = 0.0
    
    @State var pressure : Double = 0.0
    
    @State var ambientLight : Double = 0.0
    
    @State var hasPassedDebounceThreshold = true
    
    @State var gradeUnits : GradeUnits = .percentGrade
        
    let debounceThresholdGrade = 1.0

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
                        Text(String(format: "%.2f", abs(grade!)) + "°")
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
                
                if(cameraBasedLevel){
                    ZStack{
                        CameraView()
                        ReticleView()
                    }
                    .frame(height: previewHeight)
                    .transition(.move(edge: .leading))
                    
                } else{
                    SlopeVisualizerView(height: previewHeight, grade: $grade)
                        .transition(.move(edge: .trailing))
                    //.transition(.scale(scale: 0.0, anchor: UnitPoint(x: 0.1, y: 0.0)))
                    
                }
            } else{
                Spacer()
                Text("Initializing...")
                ProgressView()
                Spacer()
            }
                /*
            HStack{
                Text("Elevation: \(Int(locationManager.altitude)) ft")
                Spacer()
            }
            HStack{
                Text("Pressue: \(Int(pressure)) bar")
                Spacer()
            }
            HStack{
                Text("Luminosity: \(Int(sensorKitManager.ambientLightLevel)) lux")
                Spacer()
            }*/
            Spacer()
            HStack{
                Text("Alignment:")
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
            .padding()
            
            Picker("Units:", selection: $gradeUnits) {
                Text("Percent Grade").tag(GradeUnits.percentGrade)
                Text("Degrees").tag(GradeUnits.degrees)
            }
            .pickerStyle(SegmentedPickerStyle())
            /*
            Picker("Units:", selection: $cameraBasedLevel) {
                HStack{
                    Text("Plane")
                    //Image(systemName: "righttriangle.fill")
                }
                .tag(false)
                HStack{
                    Text("Camera")
                    //Image(systemName: "camera")
                }
                .tag(true)
                //Text("Camera").tag(false)
                //Text("Level").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())*/
            /*
            HStack{
                Text("Alignment:")
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
        }
        .padding(5.0)
        .onAppear {
            self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical,  to: self.queue) { (data: CMDeviceMotion?, error: Error?) in
                guard let data = data else {
                    print("Error: \(error!)")
                    return
                }
                
                let attitude: CMAttitude = data.attitude
                
                DispatchQueue.main.async {
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
                    switch gradeUnits {
                    case .degrees:
                        grade = theta * 180 / 3.141528
                    case .percentGrade:
                        grade = newGrade
                    }
                    
                }
            }
            /*
            //self.sensorKitManager.startMonitoring()
            //self.barometer.startRecording()
            //self.barometer.
            
            //let barometer = SRSensor(rawValue: "ambientPressure")
            
            
            //self.ambientLightSensor.
            
            */
        }
    }
}

#Preview {
    ContentView()
}
