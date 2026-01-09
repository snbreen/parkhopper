//
//  ContentView.swift
//  ParkEats
//
//  Created by Sam Breen on 11/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some View {
        Group {
            if loginViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .environmentObject(loginViewModel)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    
    var body: some View {
        TabView {
            ParkListView()
                .tabItem {
                    Label("Parks", systemImage: "star.circle.fill")
                }
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            AddReviewView()
                .tabItem {
                    Label("Add Review", systemImage: "plus.circle.fill")
                }
            
//            CollectionsView()
//                .tabItem {
//                    Label("Collections", systemImage: "star.fill")
//                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
