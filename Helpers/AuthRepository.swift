//
//  AuthRepository.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import Firebase
import FirebaseCore
import FirebaseFirestore
import Combine

//protocol for this business
protocol AuthRepositoryProtocol {
    func signInWithGoogle() async throws -> AppUser
        func signIn(email: String, password: String) async throws -> AppUser
        func signUp(email: String, password: String) async throws -> AppUser
        func signOut() throws
        func getCurrentUser() -> AppUser?
        var isAuthenticated: Bool { get }
}

class AuthRepository: AuthRepositoryProtocol {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    @Published private(set) var currentUser: AppUser?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    //initializing
    init() {
        setupAuthListener()
    }
    //take it down once its done
    deinit {
            if let listener = authStateListener {
                auth.removeStateDidChangeListener(listener)
            }
        }
    
    //get the listener stored and start handling the sign in
    private func setupAuthListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                Task {
                    await self?.handleUserSignIn(firebaseUser: firebaseUser)
                }
            } else {
                DispatchQueue.main.async {
                    self?.currentUser = nil
                }
            }
        }
    }

    //pop the user in the firebase database
    private func handleUserSignIn(firebaseUser: User) async {
            let appUser = firebaseUser.toAppUser()
            
            //save user in firestore
            await saveUserToFirestore(user: appUser)
            
            //load full user data from firestore
            await loadUserFromFirestore(uid: appUser.uid)
        }
        
        //helper function for popping the user into the firebase database
        private func saveUserToFirestore(user: AppUser) async {
            do {
                try db.collection("users").document(user.uid).setData(from: user, merge: true)
            } catch {
                print("Error saving user to Firestore: \(error)")
            }
        }
        
        //grab the user from the database
        private func loadUserFromFirestore(uid: String) async {
            do {
                let document = try await db.collection("users").document(uid).getDocument()
                if let user = try? document.data(as: AppUser.self) {
                    DispatchQueue.main.async {
                        self.currentUser = user
                    }
                } else {
                    //create default user if not found
                    let defaultUser = AppUser(
                        uid: uid,
                        email: auth.currentUser?.email,
                        displayName: auth.currentUser?.displayName,
                        photoURL: auth.currentUser?.photoURL?.absoluteString
                    )
                    DispatchQueue.main.async {
                        self.currentUser = defaultUser
                    }
                }
            } catch {
                print("Error loading user from Firestore: \(error)")
            }
        }
    
    //all the google sign in shenanigans and then save the user created into the database
    func signInWithGoogle() async throws -> AppUser {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationError
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.viewControllerError
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.tokenError
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        
        let authResult = try await auth.signIn(with: credential)
        let newUser = AppUser(
                    uid: authResult.user.uid,
                    email: authResult.user.email,
                    displayName: authResult.user.displayName,
                    photoURL: authResult.user.photoURL?.absoluteString
                )
        await saveUserToFirestore(user: newUser)
        return newUser
    }
    
    //already have an account, sign on in
    func signIn(email: String, password: String) async throws -> AppUser {
            let authResult = try await auth.signIn(withEmail: email, password: password)
        let currUser: AppUser = AppUser(
            uid: authResult.user.uid,
            email: authResult.user.email,
            displayName: authResult.user.displayName,
            photoURL: authResult.user.photoURL?.absoluteString
        )
            return currUser
        }
        
        //new account, sign up instead
        func signUp(email: String, password: String) async throws -> AppUser {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            
            // Update display name to be the part before @ in email
            let displayName = email.components(separatedBy: "@").first ?? "User"
            
            // Update profile with display name
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            
            let newUser: AppUser = AppUser(
                uid: authResult.user.uid,
                email: authResult.user.email,
                displayName: displayName,
                photoURL: authResult.user.photoURL?.absoluteString
            )
            try await changeRequest.commitChanges()
            await saveUserToFirestore(user: newUser)
            
            
            return newUser
        }
    //for logging out
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
    }
    
    //pretty self explanatory just grab that guy
    func getCurrentUser() -> AppUser? {
        currentUser
    }
}


//turns my firebase user into an AppUser, aka my app's user model
extension User {
    func toAppUser() -> AppUser {
        AppUser(
            uid: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL?.absoluteString
        )
    }
}

//errors galore
enum AuthError: Error, LocalizedError {
    case configurationError
    case viewControllerError
    case tokenError
    case signInError(String)
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .configurationError:
            return "Authentication configuration error"
        case .viewControllerError:
            return "Unable to present sign in view"
        case .tokenError:
            return "Authentication token error"
        case .signInError(let message):
            return message
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password should be at least 6 characters"
        case .wrongPassword:
            return "Incorrect password"
        case .userNotFound:
            return "No account found with this email"
        case .networkError:
            return "Network error. Please check your connection"
        }
    }
}
