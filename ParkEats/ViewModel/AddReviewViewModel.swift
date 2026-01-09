//
//  AddReviewViewModel.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import PhotosUI
import UIKit
import Combine
import Photos
import SwiftUI


class AddReviewViewModel: ObservableObject {
    @Published var selectedPark: Park?
    @Published var rating = 0
    @Published var reviewText = ""
    @Published var priceRange: Review.PriceRange = .moderate
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitted = false
    
    private let reviewRepository: ReviewRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init (
        reviewRepository: ReviewRepositoryProtocol = ReviewRepository(),
        authRepository: AuthRepositoryProtocol = AuthRepository()
    ) {
        self.reviewRepository = reviewRepository
        self.authRepository = authRepository
    }
    
    //here we go we gotta load these images from the photopicker
    func loadImages(from items: [PhotosPickerItem]) async {
        selectedImages.removeAll()
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }
    
    //submit that thang, call the repository so it can get all the database shenanigans done
    func submitReview() async {
        guard let park = selectedPark,
              let user = authRepository.getCurrentUser() else {
            errorMessage = "Please select a park and ensure you're logged in"
            return
        }
        
        guard rating > 0 else {
            errorMessage = "Please provide a rating"
            return
        }
        
        guard !reviewText.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please write a review"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let review = Review(
            parkId: park.id ?? "",
            userId: user.uid,
            userName: user.displayName ?? "Anonymous",
            userPhotoURL: user.photoURL,
            rating: rating,
            text: reviewText,
            photoURLs: [],
            priceRange: priceRange,
            timestamp: Date()
        )
        
        do {
            try await reviewRepository.submitReview(review, images: selectedImages)
            isSubmitted = true
            clearForm()
        } catch {
            errorMessage = "Failed to submit review: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    //clear it up, we'll call this after it gets submitted
    private func clearForm() {
        selectedPark = nil
        rating = 0
        reviewText = ""
        priceRange = .moderate
        selectedImages.removeAll()
    }
    
    var canSubmit: Bool {
        selectedPark != nil && rating > 0 && !reviewText.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
