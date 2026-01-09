//
//  ProfileView.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            List {
                //username and email section
                Section {
                    HStack {
                        if let user = viewModel.user {
                            VStack(alignment: .leading, spacing: 4) {
                                //it wouldn't let me just have the display name but it's alright
                                Text(user.displayName ?? "Anonymous User")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Not signed in")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                //number of reviews and favorites
                Section("Stats") {
                    HStack {
                        StatView(count: viewModel.reviewCount, label: "Reviews")
                        Divider()
                        StatView(count: viewModel.favoriteCount, label: "Favorites")
                    }
                    .frame(height: 60)
                }
                
                //you can see a mini view of some of the recent reviews
                if !viewModel.recentReviews.isEmpty {
                    Section("Recent Reviews") {
                        ForEach(viewModel.recentReviews) { review in
                            ReviewRowView(review: review)
                        }
                    }
                }
                
                //sign out button
                Section {
                    Button("Sign Out", role: .destructive) {
                        viewModel.signOut()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Profile")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                viewModel.loadUserData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .favoritesChanged)) { _ in
                viewModel.loadUserData()
            }
        }
    }
}

//helper for the stats section
struct StatView: View {
    let count: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

//helper for the mini reviews
struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            //show the id of the park you reviewed
            HStack {
                Text(review.parkId)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                //show the number of stars you gave
                HStack(spacing: 2) {
                    ForEach(1..<6) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            //show what you wrote
            Text(review.text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            //show when you made the review 
            Text(review.timestamp, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
