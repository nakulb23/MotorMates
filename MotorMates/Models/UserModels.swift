import Foundation
import SwiftData
import SwiftUI

// MARK: - User Profile Model
@Model
class UserProfile {
    var id: UUID
    var email: String
    var name: String
    var dateOfBirth: Date?
    var city: String
    var state: String
    var country: String
    var profilePhotoFileName: String?
    var createdAt: Date
    var lastModified: Date
    
    // Account Status
    var isActive: Bool
    var emailVerified: Bool
    
    // Authentication Provider
    var authProvider: AuthProvider
    var providerUserId: String? // Apple ID, Google ID, etc.
    
    // CloudKit Integration
    var cloudKitRecordID: String?
    var needsCloudKitSync: Bool
    
    init(email: String, name: String = "", city: String = "", state: String = "", country: String = "", authProvider: AuthProvider = .email, providerUserId: String? = nil) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.dateOfBirth = nil
        self.city = city
        self.state = state
        self.country = country
        self.profilePhotoFileName = nil
        self.createdAt = Date()
        self.lastModified = Date()
        self.isActive = true
        self.emailVerified = authProvider != .email // Social logins are pre-verified
        self.authProvider = authProvider
        self.providerUserId = providerUserId
        self.cloudKitRecordID = nil
        self.needsCloudKitSync = true
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name
    }
    
    var username: String {
        return "@" + (name.lowercased().replacingOccurrences(of: " ", with: "_"))
    }
    
    var location: String {
        var locationParts: [String] = []
        if !city.isEmpty { locationParts.append(city) }
        if !state.isEmpty { locationParts.append(state) }
        if !country.isEmpty { locationParts.append(country) }
        return locationParts.joined(separator: ", ")
    }
    
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year
    }
    
    var profilePhotoURL: URL? {
        guard let fileName = profilePhotoFileName,
              let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("ProfilePhotos").appendingPathComponent(fileName)
    }
    
    // MARK: - Profile Management
    func updateProfile(name: String, dateOfBirth: Date?, city: String, state: String, country: String) {
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.city = city
        self.state = state
        self.country = country
        self.lastModified = Date()
        self.needsCloudKitSync = true
    }
    
    func updateProfilePhoto(fileName: String?) {
        self.profilePhotoFileName = fileName
        self.lastModified = Date()
        self.needsCloudKitSync = true
    }
}

// MARK: - Authentication State
enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(UserProfile)
    case error(String)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Authentication Provider
enum AuthProvider: String, CaseIterable, Codable {
    case email = "email"
    case apple = "apple"
    case google = "google"
    
    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        }
    }
    
    var icon: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .apple:
            return "applelogo"
        case .google:
            return "globe"
        }
    }
}