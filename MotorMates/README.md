# MotorMates 🚗

**A social automotive app for car enthusiasts to share drives, manage their garage, and discover scenic routes.**

[![iOS](https://img.shields.io/badge/iOS-15.0+-000000?style=flat&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-0052CC?style=flat&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)

## ✨ Features

### 🔐 **Multi-Provider Authentication**
- **Email/Password** registration and login
- **Apple Sign-In** integration
- **Google Sign-In** with custom icon
- **Browse-first UX** - explore without account, authenticate only when posting

### 📱 **Core Functionality**
- **Feed**: Share automotive posts, photos, and experiences
- **Garage**: Manage your car collection with detailed specs
- **Drives**: Create, save, and share scenic driving routes
- **Settings**: Profile management and app preferences

### 🏗️ **Technical Architecture**
- **SwiftUI** for modern iOS interface
- **SwiftData** for local data persistence
- **CloudKit** integration for data sync
- **MapKit** for route mapping and navigation
- **PhotosUI** for image handling
- **MVVM** architecture pattern

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+**
- **iOS 15.0+** deployment target
- **macOS 12.0+** for development
- **Apple Developer Account** (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/nakulb23/MotorMates.git
   cd MotorMates
   ```

2. **Open in Xcode**
   ```bash
   open MotorMates.xcodeproj
   ```

3. **Configure Bundle Identifier**
   - Select the MotorMates project in Xcode
   - Update Bundle Identifier to your unique identifier
   - Configure your Apple Developer Team

4. **Build and Run**
   - Select your target device or simulator
   - Press `⌘ + R` to build and run

## 🔧 Configuration

### CloudKit Setup
1. Enable CloudKit in your Apple Developer Account
2. Configure CloudKit container in Xcode:
   - Go to Project Settings → Signing & Capabilities
   - Add CloudKit capability
   - Configure container identifier

### Google Sign-In Setup
1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google Sign-In API
3. Download `GoogleService-Info.plist`
4. Add the plist file to your Xcode project

### Apple Sign-In Setup
1. Enable "Sign in with Apple" in your Apple Developer Account
2. Configure in Xcode:
   - Go to Signing & Capabilities
   - Add "Sign in with Apple" capability

## 📁 Project Structure

```
MotorMates/
├── Views/                          # SwiftUI Views
│   ├── Auth/                      # Authentication screens
│   │   ├── AuthenticationView.swift
│   │   ├── AuthenticationWrapperView.swift
│   │   └── ProfileSetupView.swift
│   ├── Feed/                      # Social feed functionality
│   │   └── FeedView.swift
│   ├── Garage/                    # Car management
│   │   └── GarageView.swift
│   ├── Drives/                    # Route creation and sharing
│   │   ├── DrivesView.swift
│   │   ├── CreateRouteView.swift
│   │   └── RouteDetailView.swift
│   └── Settings/                  # User preferences
│       ├── SettingsView.swift
│       └── EditProfileView.swift
├── Models/                        # Data models
│   ├── UserModels.swift
│   └── DriveModels.swift
├── Services/                      # Business logic and APIs
│   ├── AuthenticationService.swift
│   ├── CloudKitSyncService.swift
│   ├── ShareService.swift
│   └── ThemeManager.swift
├── Map/                          # MapKit components
│   └── DriveMapView.swift
└── Assets.xcassets/              # App resources and images
```

## 🎯 User Experience Flow

### Guest Users (No Account)
- ✅ Browse feed with sample posts
- ✅ View driving routes
- ✅ Explore garage features
- ✅ Access app settings
- ❌ Cannot post, add cars, or create routes

### Authenticated Users
- ✅ All guest features
- ✅ Create and share posts
- ✅ Add cars to personal garage
- ✅ Create and save driving routes
- ✅ Edit profile and preferences
- ✅ Data synced via CloudKit

## 🛠️ Development

### Running Tests
```bash
# In Xcode
⌘ + U
```

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Maintain MVVM architecture

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🔮 Future Server Integration

This iOS app is designed to work with a backend server for enhanced functionality:

### Planned Server Features
- **User Authentication API** - JWT token-based auth
- **Post Management** - Create, read, update, delete posts
- **Route Sharing** - Public route discovery
- **Real-time Features** - Live location sharing
- **Push Notifications** - Social interactions
- **Content Moderation** - Community guidelines

### API Endpoints Structure
```
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /posts/feed
POST   /posts
GET    /routes/discover
POST   /routes
GET    /users/profile
PUT    /users/profile
```

See `SERVER_SETUP.md` for detailed backend hosting instructions.

## 📱 Screenshots

*Screenshots will be added once the app is running on your device*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

## 🙏 Acknowledgments

- Built with SwiftUI and modern iOS development practices
- Icons provided by SF Symbols
- Google Sign-In integration
- Apple Sign-In implementation

## 📧 Support

For support, please open an issue on GitHub or contact the development team.

---

**MotorMates** - Connecting automotive enthusiasts through shared drives and experiences! 🚗💨