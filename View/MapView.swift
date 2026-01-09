//
//  MapView.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import SwiftUI
import MapKit
import FirebaseFirestoreInternal

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingParkDetail = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    //base of parks involved since the database is tweaking
    let parks: [Park] = [
            Park(
                id: "disneyland",
                name: "Disneyland Park",
                location: GeoPoint(latitude: 33.8121, longitude: -117.9190),
                description: "The original Disney theme park in Anaheim, California with classic attractions like Space Mountain and Pirates of the Caribbean.",
                imageURL: nil,
                averageRating: 4.7,
                reviewCount: 1250,
                categories: ["Theme Park", "Family", "California", "Disney"]
            ),
            Park(
                id: "magic-kingdom",
                name: "Magic Kingdom",
                location: GeoPoint(latitude: 28.4177, longitude: -81.5812),
                description: "The first Walt Disney World theme park in Florida, home to Cinderella's Castle and classic Disney attractions.",
                imageURL: nil,
                averageRating: 4.8,
                reviewCount: 1850,
                categories: ["Theme Park", "Family", "Florida", "Disney"]
            ),
            Park(
                id: "universal-hollywood",
                name: "Universal Studios Hollywood",
                location: GeoPoint(latitude: 34.1381, longitude: -118.3534),
                description: "Movie-based theme park with thrilling rides, studio tours, and The Wizarding World of Harry Potter.",
                imageURL: nil,
                averageRating: 4.5,
                reviewCount: 980,
                categories: ["Theme Park", "Movies", "California", "Universal"]
            ),
            Park(
                id: "epcot",
                name: "Epcot",
                location: GeoPoint(latitude: 28.3747, longitude: -81.5494),
                description: "Educational theme park with Future World technology exhibits and World Showcase international pavilions.",
                imageURL: nil,
                averageRating: 4.6,
                reviewCount: 1100,
                categories: ["Theme Park", "Educational", "Florida", "Disney"]
            ),
            Park(
                id: "animal-kingdom",
                name: "Disney's Animal Kingdom",
                location: GeoPoint(latitude: 28.3556, longitude: -81.5902),
                description: "Animal-themed park with safari adventures, Avatar: Flight of Passage, and wildlife encounters.",
                imageURL: nil,
                averageRating: 4.4,
                reviewCount: 920,
                categories: ["Theme Park", "Animals", "Florida", "Disney"]
            ),
            Park(
                id: "california-adventure",
                name: "Disney California Adventure",
                location: GeoPoint(latitude: 33.8081, longitude: -117.9210),
                description: "Disney park celebrating California's history and culture, with Marvel superhero areas and Pixar attractions.",
                imageURL: nil,
                averageRating: 4.3,
                reviewCount: 850,
                categories: ["Theme Park", "California", "Disney"]
            ),
            Park(
                id: "universal-florida",
                name: "Universal Studios Florida",
                location: GeoPoint(latitude: 28.4746, longitude: -81.4684),
                description: "Orlando theme park with movie-themed rides, shows, and attractions from Harry Potter to Jurassic Park.",
                imageURL: nil,
                averageRating: 4.6,
                reviewCount: 1350,
                categories: ["Theme Park", "Movies", "Florida", "Universal"]
            ),
            Park(
                id: "islands-adventure",
                name: "Islands of Adventure",
                location: GeoPoint(latitude: 28.4720, longitude: -81.4662),
                description: "Universal's thrill-ride park with Marvel Super Hero Island, The Wizarding World of Harry Potter, and Jurassic Park.",
                imageURL: nil,
                averageRating: 4.7,
                reviewCount: 1200,
                categories: ["Theme Park", "Thrill Rides", "Florida", "Universal"]
            ),
            Park(
                id: "seaworld",
                name: "SeaWorld Orlando",
                location: GeoPoint(latitude: 28.4112, longitude: -81.4624),
                description: "Marine-life theme park with animal shows, aquariums, and roller coasters.",
                imageURL: nil,
                averageRating: 4.2,
                reviewCount: 750,
                categories: ["Theme Park", "Animals", "Marine Life", "Florida"]
            ),
            Park(
                id: "legoland",
                name: "Legoland Florida",
                location: GeoPoint(latitude: 28.3322, longitude: -81.6301),
                description: "Theme park built from Lego bricks with rides, shows, and building activities for families.",
                imageURL: nil,
                averageRating: 4.1,
                reviewCount: 600,
                categories: ["Theme Park", "Family", "Lego", "Florida"]
            )
        ]
    
    var body: some View {
        NavigationView {
            //start it up with the starting camera position, either user location or the disneyland coordinates if that doesn't work
            ZStack(alignment: .top) {
                
                Map(position: $cameraPosition, selection: $viewModel.selectedParkId) {
                    
                    UserAnnotation()
                    
                    //give each park it's own little pin in the map
                    ForEach(parks) { park in
                        Annotation(park.name, coordinate: park.coordinate) {
                            MapPinView(park: park)
                                .onTapGesture {
                                    viewModel.selectPark(park)
                                    showingParkDetail = true
                                }
                        }
                        .tag(park.id)
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                //if they tap on the pin then go ahead and show details
                .sheet(isPresented: $showingParkDetail) {
                    if let park = viewModel.selectedPark {
                        ParkDetailView(park: park, viewModel: ParkListViewModel())
                    }
                }
//                .onChange(of: viewModel.region) { newRegion in
//                                    withAnimation {
//                                        cameraPosition = .region(newRegion)
//                                    }
//                                }
                .onAppear {
                    //set initial camera position
                    cameraPosition = .region(viewModel.region)
                }
                
                VStack{
                    //center on user button
                    HStack {
                        Spacer()
                        Button(action: viewModel.centerOnUser) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(.trailing)
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MapPinView: View {
    let park: Park
    
    var body: some View {
        VStack(spacing: 0) {
            //displays this cute little star decal as the pin
            Image(systemName: "star.circle.fill")
                .font(.title)
                .foregroundColor(.blue)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                )
            //displays the park's name also
            Text(park.name)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }
}


struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
