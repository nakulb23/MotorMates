import SwiftUI
import PhotosUI

struct FeedView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var showingCreatePost = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header (only show when posts are empty)
                    if posts.isEmpty {
                        welcomeHeader
                    }
                    
                    if posts.isEmpty {
                        EmptyFeedView()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostView(post: post)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, posts.isEmpty ? 20 : 8)
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                        Text("MotorMates")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        if authService.currentUser != nil {
                            showingCreatePost = true
                        } else {
                            // Show auth prompt for posting
                            showingCreatePost = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .refreshable {
                await loadPosts()
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView()
        }
        .task {
            await loadPosts()
        }
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 16) {
            // Personal Welcome
            if let user = authService.currentUser {
                VStack(spacing: 8) {
                    Text("Welcome back, \(user.displayName.components(separatedBy: " ").first ?? "Driver")!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Ready for your next automotive adventure?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Actions
            quickActionsSection
        }
        .padding(.horizontal)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Create Route",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // Will navigate to drives tab and show create route
                }
                
                QuickActionCard(
                    title: "Share Post",
                    icon: "camera.fill",
                    color: .orange
                ) {
                    showingCreatePost = true
                }
                
                QuickActionCard(
                    title: "Browse Routes",
                    icon: "map.fill",
                    color: .green
                ) {
                    // Will navigate to drives tab
                }
                
                QuickActionCard(
                    title: "My Garage",
                    icon: "car.fill",
                    color: .purple
                ) {
                    // Will navigate to garage tab
                }
            }
        }
    }
    
    private func loadPosts() async {
        isLoading = true
        
        // Load sample posts for browsing (even without authentication)
        let sampleUsers = [
            User(username: "@mike_drives", displayName: "Mike Johnson", location: "San Francisco, CA", carsCount: 2),
            User(username: "@sarah_automotive", displayName: "Sarah Chen", location: "Los Angeles, CA", carsCount: 1),
            User(username: "@alex_roadtrip", displayName: "Alex Rodriguez", location: "Austin, TX", carsCount: 3)
        ]
        
        let samplePosts = [
            Post(
                user: sampleUsers[0],
                caption: "Perfect morning drive through the Golden Gate Bridge! The fog rolling in made it absolutely magical. #GoldenGate #MorningDrive",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                likesCount: 24,
                commentsCount: 8,
                tags: ["scenic", "bridge"],
                location: "San Francisco, CA"
            ),
            Post(
                user: sampleUsers[1],
                caption: "Finally took my new Tesla Model 3 on the Pacific Coast Highway. The views were incredible! Can't wait to do this route again.",
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                likesCount: 45,
                commentsCount: 12,
                tags: ["tesla", "coastal", "pch"],
                location: "Malibu, CA"
            ),
            Post(
                user: sampleUsers[2],
                caption: "Weekend road trip to Hill Country was amazing! My Jeep handled the trails perfectly. Already planning the next adventure.",
                timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                likesCount: 18,
                commentsCount: 5,
                tags: ["offroad", "jeep", "adventure"],
                location: "Texas Hill Country"
            )
        ]
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        posts = samplePosts
        isLoading = false
    }
}

struct PostView: View {
    let post: Post
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(post.user.username)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Post content
            Text(post.caption)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            // Image placeholder for production
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 250)
                .overlay(
                    VStack {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Photo")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                )
            
            // Location (if available)
            if let location = post.location {
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Interaction buttons
            HStack(spacing: 24) {
                Button(action: { isLiked.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(post.likesCount + (isLiked ? 1 : 0))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(post.commentsCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                }
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            isLiked = post.isLiked
        }
    }
}

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No posts yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Follow other users to see their automotive posts and updates!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 100)
    }
}

// MARK: - Models for FeedView
struct User: Identifiable, Codable {
    var id = UUID()
    let username: String
    let displayName: String
    let profileImage: String
    let location: String
    let followersCount: Int
    let followingCount: Int
    let carsCount: Int
    
    init(username: String, displayName: String, profileImage: String = "", location: String = "", followersCount: Int = 0, followingCount: Int = 0, carsCount: Int = 0) {
        self.id = UUID()
        self.username = username
        self.displayName = displayName
        self.profileImage = profileImage
        self.location = location
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.carsCount = carsCount
    }
}

struct Post: Identifiable, Codable {
    var id = UUID()
    let user: User
    let images: [String]
    let caption: String
    let timestamp: Date
    let likesCount: Int
    let commentsCount: Int
    let isLiked: Bool
    let tags: [String]
    let location: String?
    
    init(user: User, images: [String] = [], caption: String, timestamp: Date = Date(), likesCount: Int = 0, commentsCount: Int = 0, isLiked: Bool = false, tags: [String] = [], location: String? = nil) {
        self.id = UUID()
        self.user = user
        self.images = images
        self.caption = caption
        self.timestamp = timestamp
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLiked = isLiked
        self.tags = tags
        self.location = location
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Post View
struct CreatePostView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var caption = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingAuth = false
    
    var body: some View {
        if authService.currentUser != nil {
            createPostContent
        } else {
            authRequiredView
        }
    }
    
    private var authRequiredView: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Share Your Drive")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Create an account to share your automotive experiences with the community")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Auth Buttons
                VStack(spacing: 16) {
                    Button("Create Account") {
                        showingAuth = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
    }
    
    private var createPostContent: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create New Post")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                // Photo Selection Area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("Add Photos")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Tap to select photos from your library")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    )
                
                // Caption Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.headline)
                    TextField("Share your automotive experience...", text: $caption, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4...8)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Handle post creation
                        dismiss()
                    }) {
                        Text("Share Post")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .disabled(caption.isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    FeedView()
}