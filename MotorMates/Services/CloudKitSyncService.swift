import Foundation
import CloudKit
import SwiftData
import SwiftUI

// MARK: - CloudKit Sync Service
@MainActor
class CloudKitSyncService: ObservableObject {
    static let shared = CloudKitSyncService()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    // Record Type Names
    private struct RecordTypes {
        static let driveRoute = "DriveRoute"
        static let drivePhoto = "DrivePhoto"
        static let driveLandmark = "DriveLandmark"
    }
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.nakulb.MotorMates")
        self.database = container.privateCloudDatabase
        
        // Load last sync date
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastCloudKitSync") as? Date
    }
    
    // MARK: - Public Sync Methods
    func syncAllRoutes(_ routes: [DriveRoute]) async {
        syncStatus = .syncing
        
        do {
            // Upload new/modified routes
            for route in routes where route.needsCloudKitSync {
                try await uploadRoute(route)
            }
            
            // Download shared routes
            try await downloadSharedRoutes()
            
            syncStatus = .success
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudKitSync")
            
        } catch {
            syncStatus = .failed(error)
            syncError = error
            print("CloudKit sync failed: \(error)")
        }
    }
    
    func uploadRoute(_ route: DriveRoute) async throws {
        let record: CKRecord
        
        if let recordID = route.cloudKitRecordID {
            // Update existing record
            record = try await database.record(for: CKRecord.ID(recordName: recordID))
        } else {
            // Create new record
            let recordID = CKRecord.ID(recordName: route.id.uuidString)
            record = CKRecord(recordType: RecordTypes.driveRoute, recordID: recordID)
            route.cloudKitRecordID = recordID.recordName
        }
        
        // Set record fields
        record["name"] = route.name
        record["description"] = route.routeDescription
        record["createdAt"] = route.createdAt
        record["lastModified"] = route.lastModified
        record["difficulty"] = route.difficulty.rawValue
        record["bestSeason"] = route.bestSeason.rawValue
        record["category"] = route.category.rawValue
        record["distance"] = route.distance
        record["estimatedDuration"] = route.estimatedDuration
        record["elevationGain"] = route.elevationGain
        record["personalRating"] = route.personalRating
        record["personalNotes"] = route.personalNotes
        record["timesCompleted"] = route.timesCompleted
        record["lastCompleted"] = route.lastCompleted
        record["routePoints"] = route.routePoints
        record["waypoints"] = route.waypoints
        record["isShared"] = route.isShared
        record["shareID"] = route.shareID
        record["shareURL"] = route.shareURL?.absoluteString
        
        // Upload record
        let savedRecord = try await database.save(record)
        route.cloudKitRecordID = savedRecord.recordID.recordName
        route.needsCloudKitSync = false
        
        // Upload associated photos
        for photo in route.photos where photo.needsCloudKitSync {
            try await uploadPhoto(photo, routeRecordID: savedRecord.recordID)
        }
        
        // Upload associated landmarks
        for landmark in route.landmarks where landmark.needsCloudKitSync {
            try await uploadLandmark(landmark, routeRecordID: savedRecord.recordID)
        }
    }
    
    private func uploadPhoto(_ photo: DrivePhoto, routeRecordID: CKRecord.ID) async throws {
        let record: CKRecord
        
        if let recordID = photo.cloudKitRecordID {
            record = try await database.record(for: CKRecord.ID(recordName: recordID))
        } else {
            let recordID = CKRecord.ID(recordName: photo.id.uuidString)
            record = CKRecord(recordType: RecordTypes.drivePhoto, recordID: recordID)
            photo.cloudKitRecordID = recordID.recordName
        }
        
        // Set photo fields
        record["fileName"] = photo.fileName
        record["caption"] = photo.caption
        record["capturedAt"] = photo.capturedAt
        record["createdAt"] = photo.createdAt
        record["isKeyPhoto"] = photo.isKeyPhoto
        record["orderIndex"] = photo.orderIndex
        record["driveRoute"] = CKRecord.Reference(recordID: routeRecordID, action: .deleteSelf)
        
        if let location = photo.location {
            record["location"] = CLLocation(latitude: location.latitude, longitude: location.longitude)
        }
        
        // Upload photo file
        if let photoURL = photo.photoURL, FileManager.default.fileExists(atPath: photoURL.path) {
            let asset = CKAsset(fileURL: photoURL)
            record["photoData"] = asset
        }
        
        let savedRecord = try await database.save(record)
        photo.cloudKitRecordID = savedRecord.recordID.recordName
        photo.needsCloudKitSync = false
    }
    
    private func uploadLandmark(_ landmark: DriveLandmark, routeRecordID: CKRecord.ID) async throws {
        let record: CKRecord
        
        if let recordID = landmark.cloudKitRecordID {
            record = try await database.record(for: CKRecord.ID(recordName: recordID))
        } else {
            let recordID = CKRecord.ID(recordName: landmark.id.uuidString)
            record = CKRecord(recordType: RecordTypes.driveLandmark, recordID: recordID)
            landmark.cloudKitRecordID = recordID.recordName
        }
        
        record["name"] = landmark.name
        record["description"] = landmark.landmarkDescription
        record["location"] = CLLocation(latitude: landmark.location.latitude, longitude: landmark.location.longitude)
        record["landmarkType"] = landmark.landmarkType.rawValue
        record["createdAt"] = landmark.createdAt
        record["driveRoute"] = CKRecord.Reference(recordID: routeRecordID, action: .deleteSelf)
        
        let savedRecord = try await database.save(record)
        landmark.cloudKitRecordID = savedRecord.recordID.recordName
        landmark.needsCloudKitSync = false
    }
    
    // MARK: - Download Methods
    private func downloadSharedRoutes() async throws {
        let query = CKQuery(recordType: RecordTypes.driveRoute, predicate: NSPredicate(format: "isShared == 1"))
        query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        let (matchResults, _) = try await database.records(matching: query)
        
        for (recordID, result) in matchResults {
            switch result {
            case .success(let record):
                // Process downloaded route record
                print("Downloaded shared route: \(recordID)")
                // Convert CKRecord back to DriveRoute if needed
            case .failure(let error):
                print("Failed to download route \(recordID): \(error)")
            }
        }
    }
    
    // MARK: - Public Share Methods
    func shareRoute(_ route: DriveRoute) async throws -> CKShare {
        guard let recordID = route.cloudKitRecordID else {
            throw CloudKitError.recordNotSynced
        }
        
        let record = try await database.record(for: CKRecord.ID(recordName: recordID))
        let share = CKShare(rootRecord: record)
        
        // Configure share
        share[CKShare.SystemFieldKey.title] = route.name
        // Note: shareURL is not available in SystemFieldKey, handled differently
        // share[CKShare.SystemFieldKey.shareURL] = route.shareURL?.absoluteString
        share.publicPermission = .readOnly
        
        // Save share
        let operation = CKModifyRecordsOperation(recordsToSave: [record, share])
        operation.savePolicy = .allKeys
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    // MARK: - Account Status
    func checkAccountStatus() async -> CKAccountStatus {
        return await withCheckedContinuation { continuation in
            container.accountStatus { status, error in
                continuation.resume(returning: status)
            }
        }
    }
    
    // MARK: - Zone Setup
    func setupCustomZone() async throws {
        let zoneID = CKRecordZone.ID(zoneName: "MotorMatesZone")
        let zone = CKRecordZone(zoneID: zoneID)
        
        do {
            _ = try await database.save(zone)
            print("Custom zone created successfully")
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, which is fine
            print("Custom zone already exists")
        } catch {
            throw error
        }
    }
    
    // MARK: - Subscription Setup
    func setupSubscriptions() async throws {
        // Create subscription for route changes
        let predicate = NSPredicate(value: true)
        let subscriptionID = "DriveRouteSubscription"
        let subscription = CKQuerySubscription(
            recordType: RecordTypes.driveRoute,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        do {
            _ = try await database.save(subscription)
            print("Subscription created successfully")
        } catch let error as CKError where error.code == .serverRecordChanged {
            print("Subscription already exists")
        } catch {
            throw error
        }
    }
    
    // MARK: - Conflict Resolution
    private func resolveConflict(clientRecord: CKRecord, serverRecord: CKRecord) -> CKRecord {
        // Simple last-writer-wins strategy
        // In a production app, you might want more sophisticated conflict resolution
        
        guard let clientModified = clientRecord["lastModified"] as? Date,
              let serverModified = serverRecord["lastModified"] as? Date else {
            return serverRecord
        }
        
        return clientModified > serverModified ? clientRecord : serverRecord
    }
}

// MARK: - CloudKit Errors
enum CloudKitError: LocalizedError {
    case recordNotSynced
    case accountNotAvailable
    case quotaExceeded
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .recordNotSynced:
            return "Record has not been synced to CloudKit yet"
        case .accountNotAvailable:
            return "iCloud account is not available"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
}

// MARK: - Sync Status View
struct SyncStatusView: View {
    @StateObject private var syncService = CloudKitSyncService.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var routes: [DriveRoute]
    
    var body: some View {
        VStack(spacing: 16) {
            switch syncService.syncStatus {
            case .idle:
                idleView
            case .syncing:
                syncingView
            case .success:
                successView
            case .failed(let error):
                errorView(error)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var idleView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.accentColor)
                Text("iCloud Sync")
                    .font(.headline)
                Spacer()
                
                Button("Sync Now") {
                    Task {
                        await syncService.syncAllRoutes(routes)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if let lastSync = syncService.lastSyncDate {
                Text("Last synced: \(lastSync, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Never synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var syncingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Syncing with iCloud...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var successView: some View {
        HStack {
            Image(systemName: "checkmark.icloud")
                .foregroundColor(.green)
            
            Text("Sync successful")
                .font(.subheadline)
                .foregroundColor(.green)
            
            Spacer()
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.red)
                
                Text("Sync failed")
                    .font(.subheadline)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button("Retry") {
                    Task {
                        await syncService.syncAllRoutes(routes)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    SyncStatusView()
        .modelContainer(for: DriveRoute.self, inMemory: true)
}