//
//  SensorManager.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 9/7/24.
//
import Combine
import SensorKit

class SensorManager: ObservableObject {
    @Published var ambientLightLevel: Double = 0.0

    private var cancellables = Set<AnyCancellable>()
    
    let ambientLightReader = SRSensorReader(sensor: SRSensor.ambientLightSensor)


    init() {
        startMonitoring()
    }


        
    func startMonitoring() {
        // Simulate ambient light level updates
        self.ambientLightReader.startRecording()
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .map { _ in
                // Replace with actual sensor data fetching logic
                //self.ambientLightReader.fetch( {x in self.ambientLightLevel = x})
                Double.random(in: 0...1000) // Simulated light level in lux
            }
            
            //.assign(to: &$ambientLightLevel)
    }
}
