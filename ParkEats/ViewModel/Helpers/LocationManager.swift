//
//  LocationManager.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
    }
    //can i see your coordinates please please please
    func requestLocation() {
        locationManager.requestLocation()
    }
    //yes we got them coordinates load em up
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    //nevermind stop the loading
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    //location updating business 
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    //in case something goes haywire
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }
    
    //if we have the okay then track away
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
}
