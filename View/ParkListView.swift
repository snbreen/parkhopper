//
//  ParkListView.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import SwiftUI
import FirebaseFirestore

struct ParkListView: View {
    @State private var searchText = ""
    @State private var selectedPark: Park?
    @State private var showingDetail = false
    //base of parks
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
    
    var filteredParks: [Park] {
         if searchText.isEmpty {
             return parks
         } else {
             return parks.filter { park in
                 park.name.localizedCaseInsensitiveContains(searchText) ||
                 park.description.localizedCaseInsensitiveContains(searchText) ||
                 park.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
             }
         }
     }
     
     var body: some View {
         NavigationView {
             VStack {
                 //search Bar
                 HStack {
                     Image(systemName: "magnifyingglass")
                         .foregroundColor(.secondary)
                     
                     ParkEatsTextField(
                         text: $searchText,
                         placeholder: "Search parks...",
                         returnKeyType: .search
                     )
                     .border(Color(.gray))
                     .frame(width:200, height: 40)
                     
                     if !searchText.isEmpty {
                         Button(action: { searchText = "" }) {
                             Image(systemName: "xmark.circle.fill")
                                 .foregroundColor(.secondary)
                         }
                     }
                 }
                 .padding(.horizontal)
                 .padding(.top)
                 
                 if filteredParks.isEmpty {
                     //no results view
                     VStack(spacing: 20) {
                         Image(systemName: "binoculars")
                             .font(.system(size: 60))
                             .foregroundColor(.secondary)
                         
                         Text("No parks found")
                             .font(.title2)
                             .foregroundColor(.secondary)
                         
                         Text("Try searching for something else")
                             .font(.caption)
                             .foregroundColor(.secondary)
                     }
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
                 } else {
                     //parks list with NavigationLink so when you click on any of them it goes to their detail view
                     List(filteredParks) { park in
                         NavigationLink(destination: ParkDetailView(park: park, viewModel: ParkListViewModel())) {
                             ParkRowView(park: park)
                         }
                     }
                     .listStyle(.plain)
                 }
             }
             .navigationTitle("Parks")
         }
     }
 }


 struct ParkDetailView: View {
     let park: Park
     let viewModel: ParkListViewModel
     
     var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 20) {
                
                 VStack(alignment: .leading, spacing: 10) {
                     //gives each of them a cute star
                     HStack {
                         Image(systemName: "star.circle.fill")
                             .font(.system(size: 40))
                             .foregroundColor(.blue)
                         
                         VStack(alignment: .leading, spacing: 4) {
                             Text(park.name)
                                 .font(.title)
                                 .fontWeight(.bold)
                             
                             //rating stats
                             HStack {
                                 HStack(spacing: 2) {
                                     ForEach(1..<6) { star in
                                         //shows a filled in star for the number of stars in ratings the park has
                                         Image(systemName: star <= Int(park.averageRating.rounded()) ? "star.fill" : "star")
                                             .font(.caption)
                                             .foregroundColor(.yellow)
                                     }
                                 }
                                 
                                 Text("•")
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                                 
                                 Text(String(format: "%.1f", park.averageRating))
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                                 
                                 Text("•")
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                                 
                                 Text("\(park.reviewCount) reviews")
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                             }
                         }
                     }
                 }
                 .padding(.horizontal)
                 
                 Divider()
                 
                 //description
                 VStack(alignment: .leading, spacing: 10) {
                     Text("Description")
                         .font(.headline)
                     
                     Text(park.description)
                         .font(.body)
                         .foregroundColor(.secondary)
                 }
                 .padding(.horizontal)
                 
                 //categories
                 if !park.categories.isEmpty {
                     VStack(alignment: .leading, spacing: 10) {
                         Text("Categories")
                             .font(.headline)
                         
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack {
                                 ForEach(park.categories, id: \.self) { category in
                                     Text(category)
                                         .font(.caption)
                                         .padding(.horizontal, 12)
                                         .padding(.vertical, 6)
                                         .background(Color.blue.opacity(0.1))
                                         .foregroundColor(.blue)
                                         .cornerRadius(15)
                                 }
                             }
                         }
                     }
                     .padding(.horizontal)
                 }
                 
                 //location
                 VStack(alignment: .leading, spacing: 10) {
                     Text("Location")
                         .font(.headline)
                     
                     HStack {
                         Image(systemName: "mappin.circle.fill")
                             .foregroundColor(.red)
                         
                         VStack(alignment: .leading) {
                             Text("Latitude: \(String(format: "%.4f", park.location.latitude))")
                                 .font(.caption)
                                 .foregroundColor(.secondary)
                             
                             Text("Longitude: \(String(format: "%.4f", park.location.longitude))")
                                 .font(.caption)
                                 .foregroundColor(.secondary)
                         }
                     }
                 }
                 .padding(.horizontal)
                 
                 Spacer()
                 //add to favorites button
                 VStack(spacing: 12){
                     Button(role: .confirm, action: {
                         viewModel.toggleFavorite(parkId: park.id ?? "")
                     }) {
                         HStack {
                             Image(systemName: "star")
                                 .font(.headline)
                            Text("Add to Favorites")
                                .fontWeight(.semibold)
                         }
                         .frame(maxWidth: .infinity)
                         .padding()
                         .background(Color.yellow.opacity(0.1))
                         .foregroundColor(.yellow)
                         .cornerRadius(10)
                         .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                     }
                 }
             }
             .padding(.vertical)
         }
         .navigationTitle(park.name)
         .navigationBarTitleDisplayMode(.inline)
//         .onAppear{
//             viewModel.checkIfFavorite(parkId: park.id ?? "")
//         }
     }
 }

struct ParkRowView: View {
    let park: Park
    //how we display the parks in the lists
    var body: some View {
        HStack {
            //their little icons
            Image(systemName: "star.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
            //their name
            VStack(alignment: .leading, spacing: 4) {
                Text(park.name)
                    .font(.headline)
                //mini font of their description
                Text(park.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                //their ratings
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", park.averageRating))
                            .font(.caption)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    //number of reviews
                    Text("\(park.reviewCount) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            //little arrow on the end 
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ParkListView()
    }
}
