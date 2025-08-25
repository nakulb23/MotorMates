# MotorMates iOS App - Server Connection Guide

## 🌐 Server Information

**Server URL**: `https://golfai.duckdns.org:8443/motormates`
**Status**: ✅ Active with full social media features

## 📱 iOS App Configuration

### 1. Update Constants.swift

Replace your API configuration with:

```swift
//
//  Constants.swift
//  MotorMates
//

import Foundation

struct Constants {
    // Server Configuration
    static let baseURL = "https://golfai.duckdns.org:8443/motormates"
    
    struct API {
        // Authentication
        static let register = "/auth/register"
        static let login = "/auth/login"
        
        // Social Feed
        static let feed = "/posts/feed"
        static let createPost = "/posts"
        static let getPost = "/posts"  // + "/{post_id}"
        
        // Social Interactions
        static let likePost = "/posts"  // + "/{post_id}/like"
        static let commentPost = "/posts"  // + "/{post_id}/comment"
        
        // User Management
        static let userProfile = "/users"  // + "/{user_id}"
        static let uploadProfilePhoto = "/users"  // + "/{user_id}/photo"
        static let userPosts = "/users"  // + "/{user_id}/posts"
        static let followers = "/users"  // + "/{user_id}/followers"
        static let following = "/users"  // + "/{user_id}/following"
        static let followUser = "/users"  // + "/{user_id}/follow"
        
        // Routes & GPS
        static let discoverRoutes = "/routes/discover"
        static let createRoute = "/routes"
        
        // Garage
        static let garage = "/garage"  // + "/{user_id}"
        static let addCar = "/garage/cars"
        
        // Files & Storage
        static let uploads = "/uploads"  // + "/{file_path}"
        static let storageInfo = "/storage-info"
        
        // System
        static let health = "/health"
        static let testConnection = "/test-ios"
        static let appUpdates = "/app-updates"
    }
    
    // Request Configuration
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
    
    // Headers
    static let headers = [
        "Accept": "application/json",
        "User-Agent": "MotorMates-iOS/1.0"
    ]
}
```

### 2. Update Info.plist for SSL

Add SSL exception for the server:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>golfai.duckdns.org</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

### 3. Create API Service Manager

```swift
//
//  MotorMatesAPIService.swift
//  MotorMates
//

import Foundation
import UIKit

class MotorMatesAPIService {
    static let shared = MotorMatesAPIService()
    
    private var authToken: String?
    private var currentUserId: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    func register(email: String, password: String, name: String, city: String?, state: String?, country: String?, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        
        let url = URL(string: "\(Constants.baseURL)\(Constants.API.register)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password,
            "name": name,
            "city": city ?? "",
            "state": state ?? "",
            "country": country ?? ""
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.authToken = authResponse.token
                self.currentUserId = authResponse.user.id
                completion(.success(authResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func login(email: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let url = URL(string: "\(Constants.baseURL)\(Constants.API.login)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.authToken = authResponse.token
                self.currentUserId = authResponse.user.id
                completion(.success(authResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Social Feed
    
    func getFeed(completion: @escaping (Result<FeedResponse, Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(Constants.baseURL)\(Constants.API.feed)")!
        if let userId = currentUserId {
            urlComponents.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let feedResponse = try JSONDecoder().decode(FeedResponse.self, from: data)
                completion(.success(feedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createPost(caption: String, location: String?, tags: [String], images: [UIImage], completion: @escaping (Result<PostResponse, Error>) -> Void) {
        
        guard let userId = currentUserId else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "\(Constants.baseURL)\(Constants.API.createPost)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", 
                        forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add form fields
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(caption)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        if let location = location {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"location\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(location)\r\n".data(using: .utf8)!)
        }
        
        if !tags.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"tags\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(tags.joined(separator: ","))\r\n".data(using: .utf8)!)
        }
        
        // Add images
        for (index, image) in images.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image_\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let postResponse = try JSONDecoder().decode(PostResponse.self, from: data)
                completion(.success(postResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func likePost(_ postId: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "\(Constants.baseURL)\(Constants.API.likePost)/\(postId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "user_id=\(userId)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let likeResponse = try JSONDecoder().decode(LikeResponse.self, from: data)
                completion(.success(likeResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func commentOnPost(_ postId: String, content: String, completion: @escaping (Result<CommentResponse, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(APIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "\(Constants.baseURL)\(Constants.API.commentPost)/\(postId)/comment")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "user_id=\(userId)&content=\(content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let commentResponse = try JSONDecoder().decode(CommentResponse.self, from: data)
                completion(.success(commentResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    private func addAuthHeaders(to request: inout URLRequest) {
        Constants.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    func testConnection(completion: @escaping (Result<TestResponse, Error>) -> Void) {
        let url = URL(string: "\(Constants.baseURL)\(Constants.API.testConnection)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let testResponse = try JSONDecoder().decode(TestResponse.self, from: data)
                completion(.success(testResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - API Models

struct AuthResponse: Codable {
    let user: User
    let token: String
    let message: String
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let profilePhotoUrl: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, city, state, country
        case profilePhotoUrl = "profile_photo_url"
        case createdAt = "created_at"
    }
}

struct FeedResponse: Codable {
    let posts: [Post]
    let count: Int
    let storage: String?
    let socialFeatures: String?
    
    enum CodingKeys: String, CodingKey {
        case posts, count, storage
        case socialFeatures = "social_features"
    }
}

struct Post: Codable {
    let id: String
    let userId: String
    let userName: String
    let userPhoto: String?
    let caption: String
    let location: String?
    let imageUrls: [String]
    let tags: [String]
    let likesCount: Int
    let commentsCount: Int
    let likedByUser: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, caption, location, tags
        case userId = "user_id"
        case userName = "user_name"
        case userPhoto = "user_photo"
        case imageUrls = "image_urls"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case likedByUser = "liked_by_user"
        case createdAt = "created_at"
    }
}

struct PostResponse: Codable {
    let post: Post
    let message: String
    let storageLocation: String?
    let imagesSaved: Int?
    
    enum CodingKeys: String, CodingKey {
        case post, message
        case storageLocation = "storage_location"
        case imagesSaved = "images_saved"
    }
}

struct LikeResponse: Codable {
    let postId: String
    let userId: String
    let liked: Bool
    let action: String
    
    enum CodingKeys: String, CodingKey {
        case liked, action
        case postId = "post_id"
        case userId = "user_id"
    }
}

struct CommentResponse: Codable {
    let comment: Comment
    let message: String
}

struct Comment: Codable {
    let id: String
    let postId: String
    let userId: String
    let userName: String
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case postId = "post_id"
        case userId = "user_id"
        case userName = "user_name"
        case createdAt = "created_at"
    }
}

struct TestResponse: Codable {
    let message: String
    let timestamp: String
    let success: Bool
    let serverInfo: ServerInfo?
    
    enum CodingKeys: String, CodingKey {
        case message, timestamp, success
        case serverInfo = "server_info"
    }
}

struct ServerInfo: Codable {
    let version: String
    let host: String
    let port: Int
    let ssl: Bool
}

enum APIError: Error {
    case noData
    case notAuthenticated
    case invalidResponse
}
```

### 4. Test Connection

Add this to your app launch or settings screen:

```swift
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Test server connection on app launch
        testServerConnection()
    }
    
    private func testServerConnection() {
        MotorMatesAPIService.shared.testConnection { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Server Connected: \(response.message)")
                    // Show success UI
                case .failure(let error):
                    print("❌ Connection Failed: \(error)")
                    // Show error UI
                }
            }
        }
    }
}
```

## 🚗 Available Features

Your server supports these complete social media features:

### Social Feed
- ✅ Browse posts from all users
- ✅ Like and unlike posts  
- ✅ Comment on posts
- ✅ Upload posts with multiple photos
- ✅ Location tagging
- ✅ Hashtag support

### User System
- ✅ Registration and login
- ✅ Profile photos
- ✅ Follow/unfollow users
- ✅ View followers and following
- ✅ User post history

### Automotive Features  
- ✅ Create driving routes with GPS data
- ✅ Upload route photos
- ✅ Car garage with photos
- ✅ Discover public routes

### Data Storage
- ✅ All data stored securely on Desktop
- ✅ Encrypted user information
- ✅ Organized file storage
- ✅ Complete separation from other apps

## 🔧 API Endpoints Reference

### Authentication
- `POST /motormates/auth/register` - Create account
- `POST /motormates/auth/login` - User login

### Social Feed
- `GET /motormates/posts/feed` - Get social feed
- `POST /motormates/posts` - Create post with photos
- `GET /motormates/posts/{post_id}` - Get post details
- `POST /motormates/posts/{post_id}/like` - Like/unlike post
- `POST /motormates/posts/{post_id}/comment` - Add comment

### User Management
- `GET /motormates/users/{user_id}` - Get user profile
- `POST /motormates/users/{user_id}/photo` - Upload profile photo
- `GET /motormates/users/{user_id}/posts` - Get user's posts
- `POST /motormates/users/{user_id}/follow` - Follow/unfollow
- `GET /motormates/users/{user_id}/followers` - Get followers
- `GET /motormates/users/{user_id}/following` - Get following

### Routes & Cars
- `GET /motormates/routes/discover` - Browse public routes
- `POST /motormates/routes` - Create route with GPS + photos  
- `GET /motormates/garage/{user_id}` - Get user's cars
- `POST /motormates/garage/cars` - Add car with photos

### Files
- `GET /motormates/uploads/{file_path}` - Get uploaded files
- `GET /motormates/storage-info` - Storage statistics

### System
- `GET /motormates/health` - Server health
- `GET /motormates/test-ios` - Test iOS connection

## 🌐 Server Status

**URL**: https://golfai.duckdns.org:8443/motormates
**Status**: ✅ Active  
**SSL**: ✅ Enabled
**Features**: ✅ Complete social media platform
**Storage**: ✅ Desktop with encryption

## 🚀 Next Steps

1. **Update your iOS project** with the code above
2. **Test the connection** using the test endpoint
3. **Implement authentication** flow
4. **Build the social feed** UI
5. **Add photo upload** functionality  
6. **Deploy to TestFlight** or App Store

Your automotive social media platform is ready! 🚗📱✨

---

Need help? Check the server at: https://golfai.duckdns.org:8443/motormates