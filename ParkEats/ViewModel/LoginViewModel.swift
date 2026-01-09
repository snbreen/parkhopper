//
//  LoginViewModel.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import Combine


class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
        setupBindings()
    }
    
    //gets the repository all set up and listens to authentication state changes
    private func setupBindings() {
        if let authRepo = authRepository as? AuthRepository {
            authRepo.$currentUser
                .receive(on: DispatchQueue.main)
                .sink { [weak self] user in
                    self?.isAuthenticated = user != nil
                }
                .store(in: &cancellables)
        }
    }
    
    //calling the repository for the google sign in shenanigans
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authRepository.signInWithGoogle()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    //calling the repository for the signing out process
    func signOut() {
        do {
            try authRepository.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    //grab that user
    func getCurrentUser() -> AppUser? {
        authRepository.getCurrentUser()
    }
    
    //signing in with normal email instead of google
    func signIn(email: String, password: String) {
            isLoading = true
            errorMessage = nil
            
            Task {
                do {
                    _ = try await authRepository.signIn(email: email, password: password)
                } catch {
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
                
                isLoading = false
            }
        }
     
    //no account yet no worries, we do sign up instead 
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = nil
            
        Task {
            do {
                _ = try await authRepository.signUp(email: email, password: password)
            } catch {
                errorMessage = "Sign up failed: \(error.localizedDescription)"
            }
                
            isLoading = false
        }
    }
}

