import Foundation
import SwiftData
import MapKit
import CloudKit

// MARK: - Drive Route Model
@Model
class DriveRoute {
    var id: UUID
    var name: String
    var routeDescription: String
    var createdAt: Date
    var lastModified: Date
    
    // Route Details
    var difficulty: DifficultyLevel
    var bestSeason: BestSeason
    var category: RouteCategory
    var distance: Double // in kilometers
    var estimatedDuration: TimeInterval // in seconds
    var elevationGain: Double? // in meters
    
    // Personal Data
    var personalRating: Int // 1-5 stars
    var personalNotes: String
    var timesCompleted: Int
    var lastCompleted: Date?
    
    // Route Geometry
    @Attribute(.externalStorage) var routePoints: Data // Encoded CLLocationCoordinate2D array
    @Attribute(.externalStorage) var waypoints: Data // Encoded waypoint data
    
    // Photos
    @Relationship var photos: [DrivePhoto]
    
    // Landmarks and Points of Interest
    @Relationship var landmarks: [DriveLandmark]
    
    // Sharing
    var isShared: Bool
    var shareID: String?
    var shareURL: URL?
    
    // CloudKit Integration
    var cloudKitRecordID: String?
    var needsCloudKitSync: Bool
    
    init(
        name: String,
        routeDescription: String = "",
        difficulty: DifficultyLevel = .moderate,
        bestSeason: BestSeason = .any,
        category: RouteCategory = .scenic,
        routePoints: [CLLocationCoordinate2D] = [],
        waypoints: [RouteWaypoint] = []
    ) {
        self.id = UUID()
        self.name = name
        self.routeDescription = routeDescription
        self.createdAt = Date()
        self.lastModified = Date()
        self.difficulty = difficulty
        self.bestSeason = bestSeason
        self.category = category
        self.distance = 0.0
        self.estimatedDuration = 0
        self.elevationGain = nil
        self.personalRating = 0
        self.personalNotes = ""
        self.timesCompleted = 0
        self.lastCompleted = nil
        self.routePoints = DriveRoute.encodeCoordinates(routePoints)
        self.waypoints = DriveRoute.encodeWaypoints(waypoints)
        self.photos = []
        self.landmarks = []
        self.isShared = false
        self.shareID = nil
        self.shareURL = nil
        self.cloudKitRecordID = nil
        self.needsCloudKitSync = true
    }
    
    // MARK: - Computed Properties
    var coordinates: [CLLocationCoordinate2D] {
        return DriveRoute.decodeCoordinates(from: routePoints)
    }
    
    var routeWaypoints: [RouteWaypoint] {
        return DriveRoute.decodeWaypoints(from: waypoints)
    }
    
    var startLocation: CLLocationCoordinate2D? {
        return coordinates.first
    }
    
    var endLocation: CLLocationCoordinate2D? {
        return coordinates.last
    }
    
    var region: MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.1,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.1
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Route Management
    func updateRoute(coordinates: [CLLocationCoordinate2D], waypoints: [RouteWaypoint]) {
        self.routePoints = DriveRoute.encodeCoordinates(coordinates)
        self.waypoints = DriveRoute.encodeWaypoints(waypoints)
        self.distance = calculateDistance()
        self.estimatedDuration = calculateEstimatedDuration()
        self.lastModified = Date()
        self.needsCloudKitSync = true
    }
    
    func addPhoto(_ photo: DrivePhoto) {
        photos.append(photo)
        lastModified = Date()
        needsCloudKitSync = true
    }
    
    func addLandmark(_ landmark: DriveLandmark) {
        landmarks.append(landmark)
        lastModified = Date()
        needsCloudKitSync = true
    }
    
    func markAsCompleted() {
        timesCompleted += 1
        lastCompleted = Date()
        lastModified = Date()
        needsCloudKitSync = true
    }
    
    // MARK: - Distance Calculation
    private func calculateDistance() -> Double {
        let coords = coordinates
        guard coords.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 0..<(coords.count - 1) {
            let start = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            let end = CLLocation(latitude: coords[i + 1].latitude, longitude: coords[i + 1].longitude)
            totalDistance += start.distance(from: end)
        }
        
        return totalDistance / 1000 // Convert to kilometers
    }
    
    private func calculateEstimatedDuration() -> TimeInterval {
        // Simple estimation: average speed of 60 km/h
        return distance * 60 // minutes
    }
    
    // MARK: - Data Encoding/Decoding
    static func encodeCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> Data {
        let coordinateData = coordinates.map { coord in
            ["lat": coord.latitude, "lon": coord.longitude]
        }
        return (try? JSONSerialization.data(withJSONObject: coordinateData)) ?? Data()
    }
    
    static func decodeCoordinates(from data: Data) -> [CLLocationCoordinate2D] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Double]] else {
            return []
        }
        
        return json.compactMap { dict in
            guard let lat = dict["lat"], let lon = dict["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    static func encodeWaypoints(_ waypoints: [RouteWaypoint]) -> Data {
        return (try? JSONEncoder().encode(waypoints)) ?? Data()
    }
    
    static func decodeWaypoints(from data: Data) -> [RouteWaypoint] {
        return (try? JSONDecoder().decode([RouteWaypoint].self, from: data)) ?? []
    }
}

// MARK: - Drive Photo Model
@Model
class DrivePhoto {
    var id: UUID
    var driveRoute: DriveRoute?
    var fileName: String
    var caption: String
    var location: CLLocationCoordinate2D?
    var capturedAt: Date
    var createdAt: Date
    
    // Photo metadata
    var isKeyPhoto: Bool // Main photo for the route
    var orderIndex: Int
    
    // CloudKit
    var cloudKitRecordID: String?
    var needsCloudKitSync: Bool
    
    init(fileName: String, caption: String = "", location: CLLocationCoordinate2D? = nil, isKeyPhoto: Bool = false) {
        self.id = UUID()
        self.fileName = fileName
        self.caption = caption
        self.location = location
        self.capturedAt = Date()
        self.createdAt = Date()
        self.isKeyPhoto = isKeyPhoto
        self.orderIndex = 0
        self.cloudKitRecordID = nil
        self.needsCloudKitSync = true
    }
    
    var photoURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("DrivePhotos").appendingPathComponent(fileName)
    }
}

// MARK: - Drive Landmark Model
@Model
class DriveLandmark {
    var id: UUID
    var driveRoute: DriveRoute?
    var name: String
    var landmarkDescription: String
    var location: CLLocationCoordinate2D
    var landmarkType: LandmarkType
    var createdAt: Date
    
    // CloudKit
    var cloudKitRecordID: String?
    var needsCloudKitSync: Bool
    
    init(name: String, landmarkDescription: String = "", location: CLLocationCoordinate2D, landmarkType: LandmarkType = .pointOfInterest) {
        self.id = UUID()
        self.name = name
        self.landmarkDescription = landmarkDescription
        self.location = location
        self.landmarkType = landmarkType
        self.createdAt = Date()
        self.cloudKitRecordID = nil
        self.needsCloudKitSync = true
    }
}

// MARK: - Supporting Types
struct RouteWaypoint: Codable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let name: String
    let waypointDescription: String
    let waypointType: WaypointType
    
    init(coordinate: CLLocationCoordinate2D, name: String = "", waypointDescription: String = "", waypointType: WaypointType = .custom) {
        self.id = UUID()
        self.coordinate = coordinate
        self.name = name
        self.waypointDescription = waypointDescription
        self.waypointType = waypointType
    }
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Enumerations
enum DifficultyLevel: String, CaseIterable, Codable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case expert = "Expert"
    
    var icon: String {
        switch self {
        case .easy: return "circle.fill"
        case .moderate: return "circle.lefthalf.filled"
        case .challenging: return "circle.righthalf.filled"
        case .expert: return "circle.dashed"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .moderate: return "yellow"
        case .challenging: return "orange"
        case .expert: return "red"
        }
    }
    
    var shortName: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Medium"
        case .challenging: return "Hard"
        case .expert: return "Expert"
        }
    }
}

enum BestSeason: String, CaseIterable, Codable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"
    case any = "Any Season"
    
    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "leaf"
        case .winter: return "snowflake"
        case .any: return "calendar"
        }
    }
}

enum RouteCategory: String, CaseIterable, Codable {
    case scenic = "Scenic"
    case performance = "Performance"
    case historical = "Historical"
    case coastal = "Coastal"
    case mountain = "Mountain"
    case urban = "Urban"
    case offroad = "Off-Road"
    case track = "Track Day"
    case cruise = "Cruise"
    case adventure = "Adventure"
    
    var icon: String {
        switch self {
        case .scenic: return "camera.fill"
        case .performance: return "speedometer"
        case .historical: return "building.columns.fill"
        case .coastal: return "water.waves"
        case .mountain: return "mountain.2.fill"
        case .urban: return "building.2.fill"
        case .offroad: return "car.rear.road.lane.dashed"
        case .track: return "oval.portrait"
        case .cruise: return "car.fill"
        case .adventure: return "map.fill"
        }
    }
    
    var shortName: String {
        switch self {
        case .scenic: return "Scenic"
        case .performance: return "Fast"
        case .historical: return "Historic"
        case .coastal: return "Coast"
        case .mountain: return "Mountain"
        case .urban: return "City"
        case .offroad: return "Off-Road"
        case .track: return "Track"
        case .cruise: return "Cruise"
        case .adventure: return "Adventure"
        }
    }
}

enum WaypointType: String, CaseIterable, Codable {
    case start = "Start"
    case end = "End"
    case stop = "Stop"
    case gas = "Gas Station"
    case food = "Food"
    case scenic = "Scenic Point"
    case photo = "Photo Spot"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .start: return "play.circle.fill"
        case .end: return "stop.circle.fill"
        case .stop: return "pause.circle.fill"
        case .gas: return "fuelpump.fill"
        case .food: return "fork.knife"
        case .scenic: return "camera.viewfinder"
        case .photo: return "camera.fill"
        case .custom: return "mappin.circle.fill"
        }
    }
}

enum LandmarkType: String, CaseIterable, Codable {
    case pointOfInterest = "Point of Interest"
    case restaurant = "Restaurant"
    case gasStation = "Gas Station"
    case viewpoint = "Viewpoint"
    case historical = "Historical Site"
    case natural = "Natural Feature"
    case accommodation = "Accommodation"
    case attraction = "Attraction"
    
    var icon: String {
        switch self {
        case .pointOfInterest: return "star.fill"
        case .restaurant: return "fork.knife"
        case .gasStation: return "fuelpump.fill"
        case .viewpoint: return "binoculars.fill"
        case .historical: return "building.columns.fill"
        case .natural: return "leaf.fill"
        case .accommodation: return "bed.double.fill"
        case .attraction: return "ticket.fill"
        }
    }
}