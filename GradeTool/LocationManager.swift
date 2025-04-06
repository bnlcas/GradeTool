//
//  LocationManager.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 9/11/24.
//
import CoreLocation

// A custom location manager class that conforms to CLLocationManagerDelegate
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Published properties to update the UI
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        // Get the initial authorization status
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        // Set up the location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest//kCLLocationAccuracyReduced //  kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Request permission (you can also request .requestAlwaysAuthorization() if needed)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Delegate method called when authorization changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        // Start or stop updates based on the new status
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingLocation()
        }
    }
    
    // Delegate method called when new locations are available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Get the most recent location
        if let newLocation = locations.last {
            DispatchQueue.main.async {
                self.location = newLocation
            }
        }
    }
    
    // Handle any errors in location updates
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
}
