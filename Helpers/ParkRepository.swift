//
//  ParkRepository.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import Combine
import CoreLocation

//protocol for this business again
protocol ParkRepositoryProtocol {
    func fetchParks() async throws -> [Park]
    func fetchPark(byId id: String) async throws -> Park
    func searchParks(query: String) async throws -> [Park]
    func fetchNearbyParks(latitude: Double, longitude: Double, radius: Double) async throws -> [Park]
    func addPark(_ park: Park) async throws
}

class ParkRepository: ParkRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collectionName = "Parks"
    
    //go into the database and grab all the parks in there
    func fetchParks() async throws -> [Park] {
        let snapshot = try await db.collection(collectionName).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Park.self)
        }
    }
    
    //grab a specific park from the database
    func fetchPark(byId id: String) async throws -> Park {
        let document = try await db.collection(collectionName).document(id).getDocument()
        guard let park = try? document.data(as: Park.self) else {
            throw RepositoryError.documentNotFound
        }
        return park
    }
    
    //makes my search bar function run and filters the park that best matches your search
    func searchParks(query: String) async throws -> [Park] {
        let parks = try await fetchParks()
        return parks.filter { park in
            park.name.localizedCaseInsensitiveContains(query) ||
            park.description.localizedCaseInsensitiveContains(query) ||
            park.categories.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    //this was an idea for using user location to find the parks nearest to them, i was really ambitious when i started this project
    func fetchNearbyParks(latitude: Double, longitude: Double, radius: Double) async throws -> [Park] {
        let allParks = try await fetchParks()
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        return allParks.filter { park in
            let parkLocation = CLLocation(
                latitude: park.location.latitude,
                longitude: park.location.longitude
            )
            return userLocation.distance(from: parkLocation) <= radius
        }
    }
    
    //pop a new park in the database if needed
    func addPark(_ park: Park) async throws {
        let document = db.collection(collectionName).document()
        try document.setData(from: park)
    }
}

//errors
enum RepositoryError: Error {
    case documentNotFound
    case decodingError
    case networkError
}
