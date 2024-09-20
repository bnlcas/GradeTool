//
//  LocationManager.swift
//  GradeTool
//
//  Created by Benjamin Lucas on 9/11/24.
//
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    //MARK: Object to Access Location Services
    private let locationManager = CLLocationManager()
    
    private var continuation: CheckedContinuation<CLLocation, Error>?

    
    public var altitude : Double = -2.0
    //MARK: Set up the Location Manager Delegate
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func checkAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            return
        }
    }
    
    
    //MARK: Asynchronously request the current location
    var currentLocation: CLLocation {
        get async throws {
            return try await withCheckedThrowingContinuation { continuation in
                // 1. Set up the continuation object
                self.continuation = continuation
                // 2. Triggers the update of the current location
                locationManager.requestLocation()
                //locationManager.location?.coordinate.latitude
                altitude = locationManager.location?.altitude ?? -1.0
            }
        }
    }
}
