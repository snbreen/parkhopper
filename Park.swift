//
//  Park.swift
//  ParkEats
//
//  Created by Sam Breen on 11/19/25.
//

import Foundation
import FirebaseFirestore
import CoreLocation

//theme park model!
struct Park: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let name: String
    let location: GeoPoint
    let description: String
    let imageURL: String?
    var averageRating: Double = 0.0
    var reviewCount: Int = 0
    var categories: [String] = []
    
    static func == (lhs: Park, rhs: Park) -> Bool {
        lhs.id == rhs.id
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
}
