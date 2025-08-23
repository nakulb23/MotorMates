//
//  MotorMatesApp.swift
//  MotorMates
//
//  Created by Nakul Bhatnagar on 8/18/25.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct MotorMatesApp: App {
    @StateObject private var themeManager = ThemeManager()
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Include UserProfile in SwiftData models
            modelContainer = try ModelContainer(for: DriveRoute.self, DrivePhoto.self, DriveLandmark.self, UserProfile.self)
            print("✅ SwiftData ModelContainer initialized successfully")
        } catch {
            print("⚠️ Failed to create persistent container, trying in-memory fallback: \(error)")
            
            // Try in-memory as last resort
            do {
                let schema = Schema([DriveRoute.self, DrivePhoto.self, DriveLandmark.self, UserProfile.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                print("✅ In-memory SwiftData container created successfully")
            } catch {
                fatalError("❌ Critical: Could not create any SwiftData container: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // Allow browsing without auth, require auth only for data storage
            MotorMatesTabView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .animation(.easeInOut(duration: 0.3), value: themeManager.isDarkMode)
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .task {
                    await setupCloudKit()
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle Universal Links for shared routes
        if let shareID = ShareService.shared.handleIncomingURL(url) {
            // Navigate to shared route view
            print("Opening shared route: \(shareID)")
            // You would implement navigation logic here
        }
    }
    
    private func setupCloudKit() async {
        let syncService = CloudKitSyncService.shared
        
        // Check account status
        let accountStatus = await syncService.checkAccountStatus()
        
        switch accountStatus {
        case .available:
            do {
                try await syncService.setupCustomZone()
                try await syncService.setupSubscriptions()
                print("CloudKit setup completed successfully")
            } catch {
                print("CloudKit setup failed: \(error)")
            }
        case .noAccount:
            print("No iCloud account available")
        case .restricted:
            print("iCloud account is restricted")
        case .couldNotDetermine:
            print("Could not determine iCloud account status")
        case .temporarilyUnavailable:
            print("iCloud account temporarily unavailable")
        @unknown default:
            print("Unknown iCloud account status")
        }
    }
}

// MARK: - MotorMates Tab View
struct MotorMatesTabView: View {
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
        .tint(.orange)
    }
}


