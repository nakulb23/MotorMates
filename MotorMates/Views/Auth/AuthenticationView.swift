import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("MotorMates")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        if isSignUp {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.name)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(isSignUp ? .newPassword : .password)
                        
                        if isSignUp {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                    }
                    
                    // Email Action Button
                    Button(action: {
                        Task {
                            await handleAuthentication()
                        }
                    }) {
                        HStack {
                            if authService.authState == .authenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                    }
                    .disabled(authService.authState == .authenticating)
                    
                    // Social Login Section (only for sign in)
                    if !isSignUp {
                        // Social Login Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                            
                            Text("or")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        
                        // Social Login Buttons
                        VStack(spacing: 12) {
                            // Apple Sign-In Button
                            Button(action: {
                                Task {
                                    await authService.signInWithApple()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "applelogo")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text("Continue with Apple")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black)
                                )
                            }
                            .disabled(authService.authState == .authenticating)
                            
                            // Google Sign-In Button
                            Button(action: {
                                Task {
                                    await authService.signInWithGoogle()
                                }
                            }) {
                                HStack {
                                    Image("google")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                    
                                    Text("Continue with Google")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(authService.authState == .authenticating)
                        }
                    }
                    
                    // Toggle Sign In/Sign Up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                            clearForm()
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(authService.authState.errorMessage ?? "Unknown error occurred")
        }
        .onChange(of: authService.authState) { _, newState in
            if case .error = newState {
                showingError = true
            }
        }
    }
    
    private func handleAuthentication() async {
        guard validateForm() else { return }
        
        if isSignUp {
            await authService.signUp(email: email, password: password, name: name)
        } else {
            await authService.signIn(email: email, password: password)
        }
    }
    
    private func validateForm() -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            authService.authState = .error("Please fill in all required fields")
            return false
        }
        
        if isSignUp {
            guard !name.isEmpty else {
                authService.authState = .error("Please enter your name")
                return false
            }
            
            guard password == confirmPassword else {
                authService.authState = .error("Passwords don't match")
                return false
            }
            
            guard password.count >= 6 else {
                authService.authState = .error("Password must be at least 6 characters")
                return false
            }
        }
        
        return true
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}


#Preview {
    AuthenticationView()
}