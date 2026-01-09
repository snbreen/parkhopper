//
//  AddReviewView.swift
//  ParkEats
//
//  Created by Sam Breen on 12/3/25.
//

import SwiftUI
import PhotosUI
import SwiftUI
import PhotosUI
import FirebaseFirestore

struct AddReviewView: View {
    @StateObject private var viewModel = AddReviewViewModel()
    @State private var showingParkPicker = false
    @Environment(\.dismiss) private var dismiss
   
    
    var body: some View {
        NavigationView {
            Form {
                //park selector
                Section {
                    Button(action: { showingParkPicker = true }) {
                        HStack {
                            if let park = viewModel.selectedPark {
                                VStack(alignment: .leading) {
                                    Text(park.name)
                                        .foregroundColor(.primary)
                                    Text(park.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select a Park")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                //the rating section
                Section("Your Rating") {
                    HStack {
                        //fill in the stars when you tap them
                        ForEach(1..<6) { star in
                            Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    viewModel.rating = star
                                }
                        }
                        Spacer()
                        Text("\(viewModel.rating)/5")
                            .font(.headline)
                    }
                }
                //price range slider where you can select one of the options
                Section("Price Range") {
                    Picker("Price", selection: $viewModel.priceRange) {
                        ForEach(Review.PriceRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                //textfield for typing out the review
                Section("Review") {
                    ZStack(alignment: .topLeading) {
                        if viewModel.reviewText.isEmpty {
                            Text("Share your experience...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $viewModel.reviewText)
                            .frame(minHeight: 100)
                    }
                }
                //photo picker for adding photos to the review
                Section("Photos") {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("Add Photos (\(viewModel.selectedImages.count)/5)", systemImage: "photo")
                    }
                    .onChange(of: viewModel.selectedPhotos) {_, newItems in
                        Task {
                            await viewModel.loadImages(from: newItems)
                        }
                    }
                    //seeing the little mini pictures, if you click the x mark it'll get unselected
                    if !viewModel.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(alignment: .topTrailing) {
                                            Button(action: {
                                                viewModel.selectedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                            }
                                            .offset(x: 5, y: -5)
                                        }
                                }
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            //the top has the submit and the cancel button, one of them cancels the review and the other one submits it
            .navigationTitle("Add Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await viewModel.submitReview()
                            if viewModel.isSubmitted {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isLoading)
                }
            }
            //take the user to the full list of parks when they click on the park selector up top
            .sheet(isPresented: $showingParkPicker) {
                ParkPickerView(selectedPark: $viewModel.selectedPark)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

//the full list in question
struct ParkPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ParkListViewModel()
    @Binding var selectedPark: Park?
    @State private var searchText: String = ""
    //base of parks to choose from (database is goofed)
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
    //the filtered results when you start typing in the search bar
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
            //shows a list of the parks, when one of them gets selected the view gets dismissed or you can cancel 
            List(filteredParks) { park in
                Button(action: {
                    selectedPark = park
                    dismiss()
                }) {
                    ParkRowView(park: park)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Park")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
