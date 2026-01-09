//
//  ProfileViewModel.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import Combine
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isEditingProfile = false
    @Published var reviewCount = 0
    @Published var favoriteCount = 0
    @Published var collectionCount = 0
    @Published var recentReviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var reviewListener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    
    
    init(
        authRepository: AuthRepositoryProtocol = AuthRepository(),
        reviewRepository: ReviewRepositoryProtocol = ReviewRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.authRepository = authRepository
        self.reviewRepository = reviewRepository
        self.userRepository = userRepository
        
        setupBindings()
        loadUserData()
    }
    
    //set up repo and various listeners and listen for auth state changes
    private func setupBindings() {
        if let authRepo = authRepository as? AuthRepository {
            authRepo.$currentUser
                .receive(on: DispatchQueue.main)
                .sink { [weak self] user in
                    self?.user = user
                    if user != nil {
                        self?.setupReviewListener(userId: user!.uid)
                        self?.setupUserListener(userId: user!.uid)
                        self?.loadUserData()
                    } else {
                        self?.clearUserData()
                        self?.removeReviewListener()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    //set up listener for user related database changes
    private func setupUserListener(userId: String) {
        
        userListener?.remove()
        
        
        let db = Firestore.firestore()
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to user: \(error)")
                    return
                }
                
                
                if let snapshot = snapshot, snapshot.exists {
                    if let user = try? snapshot.data(as: AppUser.self) {
                        self.user = user
                        self.favoriteCount = user.favoriteParks.count
                    }
                }
            }
    }

    //set up listener for review database changes
    private func setupReviewListener(userId: String) {
            reviewListener?.remove()
            
            let db = Firestore.firestore()
            reviewListener = db.collection("reviews")
                .whereField("userId", isEqualTo: userId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error listening to reviews: \(error)")
                        return
                    }
                    
       
                    self.reviewCount = snapshot?.documents.count ?? 0
                    
                   
                    self.updateRecentReviews(from: snapshot)
                }
        }
        
        //force update the recent reviews so that they show the most recents
        private func updateRecentReviews(from snapshot: QuerySnapshot?) {
            guard let documents = snapshot?.documents else { return }
            
            recentReviews = documents.compactMap { document in
                try? document.data(as: Review.self)
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            .map { $0 }
        }
        
    //removes the listener for deinit purposes
        private func removeReviewListener() {
            reviewListener?.remove()
            reviewListener = nil
        }
        
        deinit {
            removeReviewListener()
        }
    
    //call the auth repo to load up the user data
    func loadUserData() {
        guard let currentUser = authRepository.getCurrentUser() else {
            clearUserData()
            return
        }
        
        user = currentUser
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadUserStats(userId: currentUser.uid)
            await loadRecentReviews(userId: currentUser.uid)
            
            
            isLoading = false
        }
    }
    
    //similar but loads specific stats
    private func loadUserStats(userId: String) async {
        do {
            
            let reviews = try await reviewRepository.fetchUserReviews(userId: userId)
            reviewCount = reviews.count
            
            favoriteCount = await userRepository.getFavoriteCount(userId: userId)
            
            
        } catch {
            errorMessage = "Failed to load user stats: \(error.localizedDescription)"
        }
    }
    
    //pretty self explanatory, grab the last 5 reviews
    private func loadRecentReviews(userId: String) async {
        do {
            let reviews = try await reviewRepository.fetchUserReviews(userId: userId)
            recentReviews = Array(reviews.prefix(5)) // Get 5 most recent
        } catch {
            errorMessage = "Failed to load reviews: \(error.localizedDescription)"
        }
    }
    
    //refresh it up
    private func clearUserData() {
        user = nil
        reviewCount = 0
        favoriteCount = 0
        collectionCount = 0
        recentReviews = []
    }
    
    //for the sign out button on the profile page, calls to the sign out method in auth repository
    func signOut() {
        do {
            try authRepository.signOut()
            clearUserData()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    //another relic from when i was going to implement a settings page, next patch maybe
    func updateProfile(displayName: String) async {
        guard let currentUser = user else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await userRepository.updateUserProfile(
                userId: currentUser.uid,
                displayName: displayName
            )
            
            user = AppUser(
                uid: currentUser.uid,
                email: currentUser.email,
                displayName: displayName,
                photoURL: currentUser.photoURL
            )
            
            isEditingProfile = false
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    //force refresh the review listener
    func refreshReviewData() {
            guard let userId = user?.uid else { return }
            
            // Force refresh by re-setting up the listener
            setupReviewListener(userId: userId)
        }
    //force refresh the user data
    func refresh() {
            loadUserData()
        }
}
