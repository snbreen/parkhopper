//
//  Review.swift
//  ParkEats
//
//  Created by Sam Breen on 11/19/25.
//

import Foundation
import UIKit
import FirebaseFirestore

//review model!
struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    let parkId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    let rating: Int
    let text: String
    let photoURLs: [String]
    let priceRange: PriceRange
    let timestamp: Date
    var likes: Int = 0
    var parkName = ""
    
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
}
