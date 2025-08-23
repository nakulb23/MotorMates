import Foundation
import SwiftData
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var currentUser: UserProfile?
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkExistingSession()
    }
    
    // MARK: - Apple Sign-In
    func signInWithApple() async {
        authState = .authenticating
        
        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [request])
            
            // For now, simulate Apple Sign-In success
            // In production, you would handle the actual Apple Sign-In flow
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Simulate successful Apple Sign-In
            let appleUser = UserProfile(
                email: "user@privaterelay.appleid.com",
                name: "Apple User",
                authProvider: .apple,
                providerUserId: "apple_user_123"
            )
            
            // Save to local storage
            modelContext?.insert(appleUser)
            try modelContext?.save()
            
            // Store session
            UserDefaults.standard.set(appleUser.email, forKey: "currentUserEmail")
            
            currentUser = appleUser
            authState = .authenticated(appleUser)
            
        } catch {
            authState = .error("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        authState = .authenticating
        
        do {
            // Simulate network delay for Google Sign-In
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Simulate successful Google Sign-In
            let googleUser = UserProfile(
                email: "user@gmail.com",
                name: "Google User",
                authProvider: .google,
                providerUserId: "google_user_123"
            )
            
            // Save to local storage
            modelContext?.insert(googleUser)
            try modelContext?.save()
            
            // Store session
            UserDefaults.standard.set(googleUser.email, forKey: "currentUserEmail")
            
            currentUser = googleUser
            authState = .authenticated(googleUser)
            
        } catch {
            authState = .error("Google Sign-In failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Email Authentication Methods
    func signUp(email: String, password: String, name: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            authState = .error("Please fill in all required fields")
            return
        }
        
        authState = .authenticating
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Check if user already exists
            if await userExists(email: email) {
                authState = .error("An account with this email already exists")
                return
            }
            
            // Create new user profile
            let newUser = UserProfile(email: email, name: name)
            newUser.emailVerified = true // In production, this would be false until email verification
            
            // Save to local storage
            modelContext?.insert(newUser)
            try modelContext?.save()
            
            // Store session
            UserDefaults.standard.set(newUser.email, forKey: "currentUserEmail")
            
            currentUser = newUser
            authState = .authenticated(newUser)
            
        } catch {
            authState = .error("Failed to create account: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            authState = .error("Please fill in all required fields")
            return
        }
        
        authState = .authenticating
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Find user in local storage
            if let user = await getUser(email: email) {
                // In production, you would validate the password here
                UserDefaults.standard.set(email, forKey: "currentUserEmail")
                currentUser = user
                authState = .authenticated(user)
            } else {
                authState = .error("Invalid email or password")
            }
            
        } catch {
            authState = .error("Sign in failed: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
        currentUser = nil
        authState = .unauthenticated
    }
    
    func deleteAccount() async {
        guard let user = currentUser else { return }
        
        do {
            // Delete profile photo if exists
            if let photoURL = user.profilePhotoURL {
                try? FileManager.default.removeItem(at: photoURL)
            }
            
            // Delete user from database
            modelContext?.delete(user)
            try modelContext?.save()
            
            // Clear session
            signOut()
            
        } catch {
            authState = .error("Failed to delete account: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Management
    func updateProfile(_ profile: UserProfile) {
        currentUser = profile
        authState = .authenticated(profile)
        
        do {
            try modelContext?.save()
        } catch {
            print("Failed to save profile updates: \(error)")
        }
    }
    
    func saveProfilePhoto(_ imageData: Data) -> String? {
        guard let user = currentUser else { return nil }
        
        // Create profile photos directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profilePhotosDir = documentsPath.appendingPathComponent("ProfilePhotos")
        
        try? FileManager.default.createDirectory(at: profilePhotosDir, withIntermediateDirectories: true)
        
        // Create unique filename
        let fileName = "profile_\(user.id.uuidString).jpg"
        let fileURL = profilePhotosDir.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save profile photo: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    private func checkExistingSession() {
        guard let email = UserDefaults.standard.string(forKey: "currentUserEmail") else {
            authState = .unauthenticated
            return
        }
        
        Task {
            if let user = await getUser(email: email) {
                currentUser = user
                authState = .authenticated(user)
            } else {
                // User not found, clear session
                UserDefaults.standard.removeObject(forKey: "currentUserEmail")
                authState = .unauthenticated
            }
        }
    }
    
    private func userExists(email: String) async -> Bool {
        return await getUser(email: email) != nil
    }
    
    private func getUser(email: String) async -> UserProfile? {
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { user in
                user.email == email
            }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            print("Failed to fetch user: \(error)")
            return nil
        }
    }
}

// MARK: - Authentication State Helpers
extension AuthenticationState {
    var isAuthenticated: Bool {
        switch self {
        case .authenticated:
            return true
        default:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}