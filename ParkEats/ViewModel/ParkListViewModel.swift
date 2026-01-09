//
//  ParkListViewModel.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import FirebaseFirestore

extension Notification.Name {
    static let favoritesChanged = Notification.Name("favoritesChanged")
}


class ParkListViewModel: ObservableObject {
    @Published var parks: [Park] = []
    @Published var filteredParks: [Park] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var sortOption: SortOption = .rating
    @Published var isFavorite = false
    
    private let userRepository: UserRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private let parkRepository: ParkRepositoryProtocol
    //private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    //get all the repos set up and get the search set up for the list page
    init(
        parkRepository: ParkRepositoryProtocol = ParkRepository(),
        userRepository: UserRepositoryProtocol = UserRepository(),
        authRepository: AuthRepositoryProtocol = AuthRepository()
    ) {
        self.parkRepository = parkRepository
        self.userRepository = userRepository
        self.authRepository = authRepository
        //self.locationManager = locationManager
        setupBindings()
        Task {
            await fetchParks()
        }
    }
    
    //getting all the search parameters together and waiting for them to change, then acting when it does
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.filterParks(searchText: searchText)
            }
            .store(in: &cancellables)
        
        $selectedCategory
            .sink { [weak self] _ in
                self?.filterParks()
            }
            .store(in: &cancellables)
        
        $sortOption
            .sink { [weak self] _ in
                self?.sortParks()
            }
            .store(in: &cancellables)
    }
    
    //i was trying to do stuff with the repo but the list wasn't loading properly
    func fetchParks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            parks = try await parkRepository.fetchParks()
            filterParks()
            sortParks()
        } catch {
            errorMessage = "Failed to load parks: \(error.localizedDescription)"
        }
        
        isLoading = false
       
    }
    
    //filter it up based on whatever you're searching
    private func filterParks(searchText: String? = nil) {
        let searchText = searchText ?? self.searchText
        
        if searchText.isEmpty && selectedCategory == nil {
            filteredParks = parks
        } else {
            filteredParks = parks.filter { park in
                let matchesSearch = searchText.isEmpty ||
                    park.name.localizedCaseInsensitiveContains(searchText) ||
                    park.description.localizedCaseInsensitiveContains(searchText)
                
                let matchesCategory = selectedCategory == nil ||
                    park.categories.contains(selectedCategory!)
                
                return matchesSearch && matchesCategory
            }
        }
        
        sortParks()
    }
    
    //cases for what search filters you have selected
    private func sortParks() {
        switch sortOption {
//        case .distance:
//            sortByDistance()
        case .rating:
            sortByRating()
        case .name:
            sortByName()
        }
    }
    
    //call the user repo to see if the park is in their favorites
    func checkIfFavorite(parkId: String) {
            guard let userId = authRepository.getCurrentUser()?.uid else {
                return
            }
            
            isLoading = true
            
            Task {
                do {
                    let isFavorite = try await userRepository.isParkInFavorites(userId: userId, parkId: parkId)
                    self.isFavorite = isFavorite
                } catch {
                    print("Error checking favorite: \(error)")
                    self.isFavorite = false
                }
                
                isLoading = false
            }
        }

    //if the user wants to add a park to favorites then we can absolutely do that
    func toggleFavorite(parkId: String) {
        guard let userId = authRepository.getCurrentUser()?.uid else {
                errorMessage = "Please sign in to add favorites"
                return
            }
            
            isLoading = true
            errorMessage = nil
            
            Task {
                do {
                    if isFavorite {
                        try await userRepository.removeParkFromFavorites(userId: userId, parkId: parkId)
                        isFavorite = false
                    } else {
                        try await userRepository.addParkToFavorites(userId: userId, parkId: parkId)
                        isFavorite = true
                    }
                    
                    // Send notification that favorites changed
                    NotificationCenter.default.post(name: .favoritesChanged, object: nil)
                    
                } catch {
                    errorMessage = "Failed to update favorites: \(error.localizedDescription)"
                }
                
                isLoading = false
            }
        }
    
    //pretty self explanatory, the things are getting sorted by rating in this mode
    private func sortByRating() {
        filteredParks.sort { $0.averageRating > $1.averageRating }
    }
    
    //pretty self explanatory, the things are getting sorted by name in this mode
    private func sortByName() {
        filteredParks.sort { $0.name < $1.name }
    }
    
    var categories: [String] {
        Set(parks.flatMap { $0.categories }).sorted()
    }
    
    //errors huzzah
    enum SortOption: String, CaseIterable {
        //case distance = "Distance"
        case rating = "Rating"
        case name = "Name"
    }
}
