//
//  LocationService.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import CoreLocation
import Combine

protocol LocationServiceProtocol: ObservableObject {
    var location: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
}

class LocationService: NSObject, ObservableObject, LocationServiceProtocol {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    //request location permissions please please please
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    //slay we've got the permissions let er rip
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
}

//similar story to the location manager
extension LocationService: CLLocationManagerDelegate{
    //location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    //in case of tomfoolery
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }
    
    //authorization checks
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
}
