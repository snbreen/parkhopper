//
//  UserRepository.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import FirebaseCore

//protocol for this business featuring more ghosts of christmas past
protocol UserRepositoryProtocol {
    func getUser(userId: String) async throws -> AppUser
    func updateUserProfile(userId: String, displayName: String) async throws
//    func getUserCollections(userId: String) async throws -> [UserCollection]
//    func addCollection(userId: String, name: String) async throws -> UserCollection
    func addParkToFavorites(userId: String, parkId: String) async throws
    func removeParkFromFavorites(userId: String, parkId: String) async throws
    func getFavoriteCount(userId: String) async -> Int
    func isParkInFavorites(userId: String, parkId: String) async throws -> Bool
}

class UserRepository: UserRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collectionName = "users"
    //private let currUser: AppUser
    
    //grab a user out of the database based on their id
    func getUser(userId: String) async throws -> AppUser {
        let document = try await db.collection(collectionName).document(userId).getDocument()
        
        guard let user = try? document.data(as: AppUser.self) else {
            throw UserError.userNotFound
        }
        
        return user
    }
    
    //i had an idea to give the user a profile picture and a settings but i ran out of time, it's here for the next patch though
    func updateUserProfile(userId: String, displayName: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "displayName": displayName,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    //the next patch continuing to haunt me
//    func getUserCollections(userId: String) async throws -> [UserCollection] {
//        let user = try await getUser(userId: userId)
//        return user.collections
//    }
//    
//    func addCollection(userId: String, name: String) async throws -> UserCollection {
//        let newCollection = UserCollection(name: name)
//        
//        try await db.collection(collectionName).document(userId).updateData([
//            "collections": FieldValue.arrayUnion([try Firestore.Encoder().encode(newCollection)])
//        ])
//        
//        return newCollection
//    }
    
    //adding a park to the favorites array
    func addParkToFavorites(userId: String, parkId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "favoriteParks": FieldValue.arrayUnion([parkId])
        ])
        var currUser: AppUser = try await getUser(userId: userId)
        currUser.favoriteParks.append(parkId)
    }
    
    //removing a park from the favorites array
    func removeParkFromFavorites(userId: String, parkId: String) async throws {
        try await db.collection(collectionName).document(userId).updateData([
            "favoriteParks": FieldValue.arrayRemove([parkId])
        ])
        var currUser: AppUser = try await getUser(userId: userId)
        currUser.favoriteParks.removeAll { $0 == parkId }
    }
    
    //how many favorites does this user have goodness gracious
    func getFavoriteCount(userId: String) async -> Int {
        do {
            let user = try await getUser(userId: userId)
            return user.favoriteParks.count
        } catch {
            return 0
        }
    }
    
    //helper to figure out if a park is already in the list so we don't double count
    func isParkInFavorites(userId: String, parkId: String) async throws -> Bool {
        let user = try await getUser(userId: userId)
        return user.favoriteParks.contains(parkId)
    }
}

//ah yes, more errors 
enum UserError: Error {
    case userNotFound
    case updateFailed
}
