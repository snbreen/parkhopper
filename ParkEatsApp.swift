//
//  ParkEatsApp.swift
//  ParkEats
//
//  Created by Sam Breen on 11/17/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        LocationManager().requestLocation()
        if let clientID = FirebaseApp.app()?.options.clientID {
                    let config = GIDConfiguration(clientID: clientID)
                    GIDSignIn.sharedInstance.configuration = config
                }
                
                return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct ParkEatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
