import SwiftUI
import SwiftData

struct AuthenticationWrapperView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            switch authService.authState {
            case .unauthenticated:
                AuthenticationView()
                
            case .authenticating:
                LoadingView()
                
            case .authenticated(let user):
                if user.name.isEmpty {
                    // Show profile setup only if name is completely empty
                    ProfileSetupView(user: user)
                } else {
                    // Show main app with TabView
                    MotorMatesTabView()
                }
                
            case .error:
                AuthenticationView()
            }
        }
        .onAppear {
            authService.configure(modelContext: modelContext)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("MotorMates")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Simple Tab View for Testing
struct SimpleTabView: View {
    var body: some View {
        TabView {
            VStack {
                Text("Feed Tab")
                    .font(.largeTitle)
                    .padding()
                Text("This is the Feed content")
                Spacer()
            }
            .background(Color.red.opacity(0.1))
            .tabItem {
                Image(systemName: "house.fill")
                Text("Feed")
            }
            
            VStack {
                Text("Drives Tab")
                    .font(.largeTitle)
                    .padding()
                Text("This is the Drives content")
                Spacer()
            }
            .background(Color.blue.opacity(0.1))
            .tabItem {
                Image(systemName: "map.fill")
                Text("Drives")
            }
            
            VStack {
                Text("Settings Tab")
                    .font(.largeTitle)
                    .padding()
                Text("This is the Settings content")
                Spacer()
            }
            .background(Color.green.opacity(0.1))
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
        }
        .tint(.orange)
    }
}

// MARK: - Main Content View
struct MainContentView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Feed")
                }
            
            GarageView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Garage")
                }
            
            DrivesView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Drives")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(.orange)
        .onAppear {
            print("🔍 MainContentView appeared - TabView should be visible!")
            
            // Make sure the tab bar appearance is set
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - App Tab Enum
enum AppTab: String, CaseIterable {
    case feed = "Feed"
    case garage = "Garage"
    case drives = "Drives"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .feed:
            return "photo.on.rectangle.angled"
        case .garage:
            return "car.fill"
        case .drives:
            return "map.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .feed:
            return "photo.on.rectangle.angled"
        case .garage:
            return "car.fill"
        case .drives:
            return "map.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - Custom Bottom Navigation Bar
struct CustomBottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? .orange : .secondary)
                            .frame(height: 24)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? .orange : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.orange.opacity(0.15) : Color.clear)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -4)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .top
        )
    }
}

#Preview {
    AuthenticationWrapperView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}