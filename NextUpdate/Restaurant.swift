//
//  Restaurant.swift
//  ParkEats
//
//  Created by Sam Breen on 11/19/25.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

enum PriceRange: String, Codable, CaseIterable {
    case cheap = "$"
    case moderate = "$$"
    case expensive = "$$$"
    case veryExpensive = "$$$$"
    
    var displayName: String {
        switch self {
        case .cheap: return "Budget Friendly"
        case .moderate: return "Moderate"
        case .expensive: return "Expensive"
        case .veryExpensive: return "Very Expensive"
        }
    }
}

struct CodableCoordinate: Codable {
    var latitude: Double
    var longitude: Double
    
    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Restaurant: Identifiable, Codable {
    var id: String
    var name: String
    var parkId: String
    var parkName: String
    var cuisineType: String
    var priceRange: PriceRange
    var codableCoordinates: CodableCoordinate
    //var coordinates: CLLocationCoordinate2D
    var description: String
    var operatingHours: String
    var contactInfo: ContactInfo?
    //var dietaryOptions: [DietOptions]
    var imageUrls: [String]
    var averageRating: Double
    var reviewCount: Int
    var isFavorite: Bool = false
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    
    var coordinates: CLLocationCoordinate2D {
           get {
               codableCoordinates.coordinate
           }
           set {
               codableCoordinates = CodableCoordinate(newValue)
           }
       }
    
    // Computed properties
    var formattedRating: String {
        String(format: "%.1f", averageRating)
    }
    
    var priceSymbols: String {
        String(repeating: "$", count: priceRange.rawValue.count)
    }
    
    enum CodingKeys: String, CodingKey {
            case id, name, parkId, parkName, cuisineType, priceRange
            case codableCoordinates = "coordinates"  // Maps to "coordinates" in JSON
            case description, operatingHours, contactInfo, imageUrls
            case averageRating, reviewCount, isFavorite, address, city, state, zipCode
        }
    
    static func createMock(
            id: String,
            name: String,
            parkId: String,
            parkName: String,
            cuisineType: String,
            priceRange: PriceRange,
            codableCoordinate: CodableCoordinate,
            coordinates: CLLocationCoordinate2D,
            description: String,
            operatingHours: String,
            contactInfo: ContactInfo? = nil,
            //dietaryOptions: [DietOptions] = [],
            imageUrls: [String] = [],
            averageRating: Double,
            reviewCount: Int = 0,
            isFavorite: Bool = false,
            address: String? = nil,
            city: String? = "Orlando",
            state: String? = "FL",
            zipCode: String? = "32830"
        ) -> Restaurant {
            return Restaurant(
                id: id,
                name: name,
                parkId: parkId,
                parkName: parkName,
                cuisineType: cuisineType,
                priceRange: priceRange,
                codableCoordinates: codableCoordinate,
                //coordinates: coordinates,
                description: description,
                operatingHours: operatingHours,
                contactInfo: contactInfo,
                //dietaryOptions: dietaryOptions,
                imageUrls: imageUrls,
                averageRating: averageRating,
                reviewCount: reviewCount,
                isFavorite: isFavorite,
                address: address,
                city: city,
                state: state,
                zipCode: zipCode
            )
        }
    }

    // Create mock ContactInfo
    func createContactInfo(phone: String, website: String? = nil, reservationrequired: Bool = false) -> ContactInfo {
        return ContactInfo(phone: phone, website: website, reservationRequired: reservationrequired)
    }

    // Helper to create coordinates
    func createCoordinate(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }



struct ContactInfo: Codable {
    let phone: String?
    let website: String?
    let reservationRequired: Bool
}


