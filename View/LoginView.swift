//
//  LoginView.swift
//  ParkEats
//
//  Created by Sam Breen on 12/5/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showEmailLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                //main title
                VStack(spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("ParkHopper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Where are we going next?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                }
                
                //if there's an error have it pop up on the screen in red font
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                if showEmailLogin {
                    //email/password/firebase auth login 
                    VStack(spacing: 16) {
                        ParkEatsTextField(
                            text: $email,
                            placeholder: "Email",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        .padding(.horizontal)
                        
                        ParkEatsTextField(
                            text: $password,
                            placeholder: "Password",
                            isSecure: true,
                            textContentType: isSigningUp ? .newPassword : .password
                        )
                        .padding(.horizontal)
                        
                        //tell the viewmodel what's going on while also either showing the sign up or sign in messages based on what the state is
                        Button(action: {
                            if isSigningUp {
                                viewModel.signUp(email: email, password: password)
                            } else {
                                viewModel.signIn(email: email, password: password)
                            }
                        }) {
                            Text(isSigningUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                        
                        Button(action: {
                            isSigningUp.toggle()
                            viewModel.errorMessage = nil
                        }) {
                            Text(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    //google sign in
                    VStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        }) {
                            //symbol for signing in with google
                            HStack {
                                Image(systemName: "g.circle.fill")
                                Text("Sign in with Google")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .disabled(viewModel.isLoading)
                        
                        Button(action: {
                            showEmailLogin = true
                            viewModel.errorMessage = nil
                        }) {
                            //symbol for signing in with email
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Sign in with Email")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .disabled(viewModel.isLoading)
                    }
                }
                //go back if we want to
                if showEmailLogin {
                    Button("Back to Login Options") {
                        showEmailLogin = false
                        email = ""
                        password = ""
                        viewModel.errorMessage = nil
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}
