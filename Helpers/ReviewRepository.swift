//
//  ReviewRepository.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import FirebaseStorage
import UIKit

//errors
enum ReviewError: Error {
    case invalidParkData
    case invalidReviewData
    case uploadFailed
}

//even more errors
enum PhotoError: Error {
    case conversionFailed
    case uploadFailed
}

//protocol for that thang
protocol ReviewRepositoryProtocol {
    func fetchReviews(forParkId parkId: String) async throws -> [Review]
    func fetchUserReviews(userId: String) async throws -> [Review]
    func submitReview(_ review: Review, images: [UIImage]) async throws
    //func likeReview(reviewId: String, userId: String) async throws
}

class ReviewRepository: ReviewRepositoryProtocol {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let collectionName = "reviews"
    
    //grab the reviews for a certain park from the database
    func fetchReviews(forParkId parkId: String) async throws -> [Review] {
        let snapshot = try await db.collection(collectionName)
            .whereField("parkId", isEqualTo: parkId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Review.self)
        }
    }
    
    //grab the reviews of a certain user should you so choose to do so
    func fetchUserReviews(userId: String) async throws -> [Review] {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Review.self)
        }
    }
    
    //handles putting a new review in the database with a helper for the images
    func submitReview(_ review: Review, images: [UIImage]) async throws {
        //image uploading
        var photoURLs: [String] = []
        for image in images {
            if let url = try? await uploadImage(image, reviewId: review.id ?? UUID().uuidString) {
                photoURLs.append(url)
            }
        }
        
        let reviewWithImages = Review(
            id: review.id,
            parkId: review.parkId,
            userId: review.userId,
            userName: review.userName,
            userPhotoURL: review.userPhotoURL,
            rating: review.rating,
            text: review.text,
            photoURLs: photoURLs,
            priceRange: review.priceRange,
            timestamp: review.timestamp
        )
        
        let document = db.collection(collectionName).document()
        try document.setData(from: reviewWithImages)
        
    }
    
    //helper for uploading the images from the photopicker
    private func uploadImage(_ image: UIImage, reviewId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw PhotoError.conversionFailed
        }
        
        let filename = "\(reviewId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference().child("reviews/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
        
    //the ghosts of christmas past (ideas i had for the app that i ran out of time to actually get working without errors)
//    private func updateParkRating(parkId: String, newRating: Int) async throws {
//        let parkRef = db.collection("parks").document(parkId)
//        
//        try await db.runTransaction({transaction, errorPointer in
//            let parkDocument: DocumentSnapshot
//            do {
//                parkDocument = try transaction.getDocument(parkRef)
//            } catch {
//                errorPointer?.pointee = error as NSError
//                throw error
//            }
//            
//            guard let data = parkDocument.data(),
//                  let oldAvg = data["averageRating"] as? Double,
//                  let oldCount = data["reviewCount"] as? Int else {
//                throw ReviewError.invalidParkData
//            }
//            
//            let newCount = oldCount + 1
//            let newAvg = ((oldAvg * Double(oldCount)) + Double(newRating)) / Double(newCount)
//            
//            transaction.updateData([
//                "averageRating": newAvg,
//                "reviewCount": newCount
//            ], forDocument: parkRef)
//            
//            return nil
//        })
//    }
    
//    func likeReview(reviewId: String, userId: String) async throws {
//        let reviewRef = db.collection(collectionName).document(reviewId)
//        
//        try await db.runTransaction({ transaction, errorPointer in
//            let reviewDocument: DocumentSnapshot
//            do {
//                reviewDocument = try transaction.getDocument(reviewRef)
//            } catch {
//                errorPointer?.pointee = error as NSError
//                throw error
//            }
//            
//            guard var data = reviewDocument.data(),
//                  var likes = data["likes"] as? Int else {
//                throw ReviewError.invalidReviewData
//            }
//            
//            // Check if user already liked
//            var likedBy = data["likedBy"] as? [String] ?? []
//            if likedBy.contains(userId) {
//                // Unlike
//                likes -= 1
//                likedBy.removeAll { $0 == userId }
//            } else {
//                // Like
//                likes += 1
//                likedBy.append(userId)
//            }
//            
//            transaction.updateData([
//                "likes": likes,
//                "likedBy": likedBy
//            ], forDocument: reviewRef)
//            
//            return nil
//        })
//    }
}

