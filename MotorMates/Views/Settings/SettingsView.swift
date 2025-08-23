import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var notificationsEnabled = true
    @State private var locationEnabled = false
    @State private var showingEditProfile = false
    @State private var showingSignOut = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let user = authService.currentUser {
                        // Authenticated User Profile
                        HStack {
                            // Profile Photo
                            if let photoURL = user.profilePhotoURL,
                               let imageData = try? Data(contentsOf: photoURL),
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(user.username)
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                
                                if !user.location.isEmpty {
                                    Text(user.location)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Text("Edit")
                                    .font(.callout)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        // Guest User Profile
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guest User")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Browsing mode")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                
                                Text("Create an account to unlock all features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Text("Sign In")
                                    .font(.callout)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Profile")
                }
                
                // Activity Section
                Section {
                    SettingsRowView(icon: "map.fill", title: "My Routes", subtitle: "View your driving routes")
                    SettingsRowView(icon: "heart", title: "Liked Posts", subtitle: "Posts you've liked")
                    SettingsRowView(icon: "bookmark", title: "Saved Posts", subtitle: "Your saved content")
                    SettingsRowView(icon: "person.2", title: "Following", subtitle: "People you follow")
                    SettingsRowView(icon: "person.3", title: "Followers", subtitle: "Your followers")
                } header: {
                    Text("Activity")
                }
                
                // Preferences Section
                Section {
                    HStack {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .font(.body)
                            Text("Get notified about likes, comments, and follows")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .tint(.orange)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location Services")
                                .font(.body)
                            Text("Share your location with posts and find local events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $locationEnabled)
                            .tint(.orange)
                    }
                    
                    SettingsRowView(icon: "paintbrush", title: "Appearance", subtitle: "Theme and display settings")
                    SettingsRowView(icon: "globe", title: "Language", subtitle: "App language settings")
                } header: {
                    Text("Preferences")
                }
                
                // Data & Privacy Section
                Section {
                    SettingsRowView(icon: "icloud", title: "iCloud Sync", subtitle: "Sync data across devices")
                    SettingsRowView(icon: "arrow.down.circle", title: "Download Data", subtitle: "Export your data")
                    SettingsRowView(icon: "trash", title: "Clear Cache", subtitle: "Free up storage space")
                } header: {
                    Text("Data & Privacy")
                }
                
                // Support Section
                Section {
                    SettingsRowView(icon: "questionmark.circle", title: "Help Center", subtitle: "Get support")
                    SettingsRowView(icon: "doc.text", title: "Terms of Service", subtitle: "Legal information")
                    SettingsRowView(icon: "hand.raised", title: "Privacy Policy", subtitle: "How we protect your data")
                    SettingsRowView(icon: "envelope", title: "Contact Us", subtitle: "Send feedback")
                    SettingsRowView(icon: "star", title: "Rate App", subtitle: "Leave a review")
                } header: {
                    Text("Support")
                }
                
                // Account Section
                if authService.currentUser != nil {
                    Section {
                        Button(action: {
                            showingSignOut = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                
                                Text("Sign Out")
                                    .font(.body)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await authService.deleteAccount()
                            }
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                
                                Text("Delete Account")
                                    .font(.body)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Account")
                    }
                }
                
                // Version Info
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            if let user = authService.currentUser {
                EditProfileView(user: user)
            } else {
                // Show authentication for guest users
                AuthenticationView()
            }
        }
        .alert("Sign Out", isPresented: $showingSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}