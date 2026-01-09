//
//  ParkService.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import FirebaseCore
import CoreLocation
import Combine

class ParkService: ObservableObject {
    @Published var parks: [Park] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let collectionName = "parks"
    private var listener: ListenerRegistration?
    
    init() {
        fetchParks()
    }
    
    deinit {
        listener?.remove()
    }
    
    //get them parks and set up the listener for parks
    func fetchParks() {
        isLoading = true
        errorMessage = nil
        
        listener = db.collection(collectionName)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error fetching parks: \(error.localizedDescription)"
                        print("Error fetching parks: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.errorMessage = "No parks found"
                        return
                    }
                    
                    self.parks = documents.compactMap { document in
                        try? document.data(as: Park.self)
                    }
                    
                    print("Loaded \(self.parks.count) parks")
                }
            }
    }
    
    //another search helper
    func searchParks(query: String) -> [Park] {
        guard !query.isEmpty else { return parks }
        
        return parks.filter { park in
            park.name.localizedCaseInsensitiveContains(query) ||
            park.description.localizedCaseInsensitiveContains(query) ||
            park.categories.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    //another one from when i was trying to do parks based around the user's location
    func getNearbyParks(userLocation: CLLocation) -> [Park] {
        return parks.sorted { park1, park2 in
            let location1 = CLLocation(
                latitude: park1.location.latitude,
                longitude: park1.location.longitude
            )
            let location2 = CLLocation(
                latitude: park2.location.latitude,
                longitude: park2.location.longitude
            )
            
            return userLocation.distance(from: location1) <
                   userLocation.distance(from: location2)
        }
    }
    
    //plain and simple, get that park
    func getPark(byId id: String) -> Park? {
        return parks.first { $0.id == id }
    }
    
    //adding a park if necessary
    func addPark(_ park: Park) async throws {
        do {
            _ = try db.collection(collectionName).addDocument(from: park)
        } catch {
            print("Error adding park: \(error)")
            throw error
        }
    }
    
    //in case we need to force a reload 
    func refresh() {
        fetchParks()
    }
}
