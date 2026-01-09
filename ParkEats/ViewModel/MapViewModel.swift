//
//  MapViewModel.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import MapKit
import Combine


class MapViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var parks: [Park] = []
    @Published var selectedPark: Park?
    @Published var selectedParkId: String?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var parkService = ParkService()
    
    private let parkRepository: ParkRepositoryProtocol
    private let locationService: any LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    //get the repos set up and set an initial location
    init(
        parkRepository: ParkRepositoryProtocol = ParkRepository(),
        locationService: any LocationServiceProtocol = LocationService()
    ) {
        self.parkRepository = parkRepository
        self.locationService = locationService
        
       
        self.region = MapViewModel.getInitialRegion(locationService: locationService)
        
        Task {
            await fetchParks()
        }
    }
    
    //if the user location thing doesn't work i just give it disneyland's coordinates lol
    private static func getInitialRegion(locationService: any LocationServiceProtocol) -> MKCoordinateRegion {
        if let userLocation = locationService.location {
            return MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        } else {
            
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 33.8121, longitude: -117.9190),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
    }
    

    //get them parks for the map
    func fetchParks() async {
        isLoading = true
        do {
            parks = try await parkRepository.fetchParks()
        } catch {
            print("Error fetching parks: \(error)")
        }
        isLoading = false
    }
    
    //another relic from the user location era, next patch ideas
    func centerOnUser() {
        if let userLocation = locationService.location {
            region.center = userLocation.coordinate
        }
    }
    
    //i used to have a search bar on the map view but i scrapped that, maybe next patch
    func searchParks() {
        guard !searchText.isEmpty else {
          
            parks = parkService.parks
            return
        }
        
       
        parks = parkService.searchParks(query: searchText)
    }
    
    //for when a user taps on a park
    func selectPark(_ park: Park) {
        selectedPark = park
        region.center = park.coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    }
    
    //reset that selection after we're done with it 
    func clearSelection() {
        selectedPark = nil
    }
}
