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
    
    @State var grade : Double = -100.0
    @State var horizontalAngle : Double = 0.0
        
    @State var cameraBasedLevel = false
    
    @State var elevation : Double = 0.0
    
    @State var pressure : Double = 0.0
    
    @State var ambientLight : Double = 0.0
    
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

            HStack{
                Text(String(format: "%.2f", abs(grade)) + "% ")
                    .frame(width: 80, height:25)
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
            }
            Spacer()
            Button(action: {
                withAnimation(Animation.linear(duration: 0.4)){
                    self.cameraBasedLevel.toggle()
                }
            }){
                HStack{
                    if(self.cameraBasedLevel){
                        Text("Plane Alignment")
                        Image(systemName: "righttriangle.fill")
                    } else {
                        Text("Camera Alignment")
                        Image(systemName: "camera")
                    }
                    Spacer()
                }
            }
        }
        .padding(5.0)
        .onAppear {
            self.altimeter.startAbsoluteAltitudeUpdates(to: self.altitudeQueue) { (data: CMAbsoluteAltitudeData?, error: Error?) in
                guard let data = data else { print( "Error: \(error!)")
                    return
                }
                
                let altitude = data.altitude
                DispatchQueue.main.async {
                    //elevation = altitude * 3.28084
                }
                //data.absolutre
            }

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
                    grade = 100 * tan(theta)

                    //grade = attitude.pitch
                }
            }
            
            //self.sensorKitManager.startMonitoring()
            //self.barometer.startRecording()
            //self.barometer.
            
            //let barometer = SRSensor(rawValue: "ambientPressure")
            
            
            //self.ambientLightSensor.
            
            
        }
    }
}

#Preview {
    ContentView()
}
