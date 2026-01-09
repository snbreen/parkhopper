//
//  User.swift
//  ParkEats
//
//  Created by Sam Breen on 11/19/25.
//

import Foundation
import Firebase
import FirebaseFirestore

//user model!
struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    var favoriteParks: [String] = []
    //var collections: [UserCollection] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    static let `default` = AppUser(
        uid: "",
        email: nil,
        displayName: nil,
        photoURL: nil
    )
}

//struct UserCollection: Identifiable, Codable {
//    var id = UUID().uuidString
//    var name: String
//    var parkIds: [String] = []
//    var createdAt: Date = Date()
//}
