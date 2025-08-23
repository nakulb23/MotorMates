import Foundation
import SwiftUI
import MapKit
import UniformTypeIdentifiers

// MARK: - Share Service
@MainActor
class ShareService: ObservableObject {
    static let shared = ShareService()
    
    private let baseURL = "https://motormates.app"
    private let routeSharePath = "/routes"
    
    private init() {}
    
    // MARK: - Universal Link Generation
    func generateShareLink(for route: DriveRoute) async -> URL? {
        // Generate a unique share ID if not already created
        if route.shareID == nil {
            route.shareID = UUID().uuidString
            route.isShared = true
        }
        
        guard let shareID = route.shareID else { return nil }
        
        // Create Universal Link
        let urlString = "\(baseURL)\(routeSharePath)/\(shareID)"
        let url = URL(string: urlString)
        
        // Store the share URL in the route for quick access
        route.shareURL = url
        route.needsCloudKitSync = true
        
        return url
    }
    
    // MARK: - Share Content Generation
    func createShareContent(for route: DriveRoute) async -> ShareContent? {
        guard let shareURL = await generateShareLink(for: route) else {
            return nil
        }
        
        let shareText = generateShareText(for: route)
        let mapImage = await generateMapSnapshot(for: route)
        
        return ShareContent(
            route: route,
            shareURL: shareURL,
            shareText: shareText,
            mapImage: mapImage
        )
    }
    
    private func generateShareText(for route: DriveRoute) -> String {
        var text = "Check out this driving route: \(route.name)"
        
        if !route.routeDescription.isEmpty {
            text += "\n\(route.routeDescription)"
        }
        
        text += "\n\n📍 Distance: \(String(format: "%.1f", route.distance)) km"
        text += "\n⏱️ Duration: \(formatDuration(route.estimatedDuration))"
        text += "\n🏷️ Category: \(route.category.rawValue)"
        text += "\n⭐ Difficulty: \(route.difficulty.rawValue)"
        
        if route.personalRating > 0 {
            let stars = String(repeating: "⭐", count: route.personalRating)
            text += "\n🌟 Rating: \(stars)"
        }
        
        text += "\n\nShared via Motor Mates"
        
        return text
    }
    
    private func generateMapSnapshot(for route: DriveRoute) async -> UIImage? {
        guard let region = route.region else { return nil }
        
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 400, height: 300)
        options.mapType = .standard
        options.showsBuildings = false
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        do {
            let snapshot = try await snapshotter.start()
            
            // Add route overlay to the snapshot
            let image = snapshot.image
            let rect = CGRect(origin: .zero, size: image.size)
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.draw(at: .zero)
            
            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(UIColor.systemBlue.cgColor)
            context?.setLineWidth(3.0)
            context?.setLineCap(.round)
            
            // Draw route line
            let coordinates = route.coordinates
            if coordinates.count > 1 {
                for i in 0..<(coordinates.count - 1) {
                    let startPoint = snapshot.point(for: coordinates[i])
                    let endPoint = snapshot.point(for: coordinates[i + 1])
                    
                    context?.move(to: startPoint)
                    context?.addLine(to: endPoint)
                }
                context?.strokePath()
            }
            
            // Add start and end markers
            if let startCoord = coordinates.first {
                let startPoint = snapshot.point(for: startCoord)
                drawMarker(at: startPoint, color: .systemGreen, context: context)
            }
            
            if let endCoord = coordinates.last, coordinates.count > 1 {
                let endPoint = snapshot.point(for: endCoord)
                drawMarker(at: endPoint, color: .systemRed, context: context)
            }
            
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return finalImage
        } catch {
            // Failed to generate map snapshot
            return nil
        }
    }
    
    private func drawMarker(at point: CGPoint, color: UIColor, context: CGContext?) {
        context?.setFillColor(color.cgColor)
        context?.fillEllipse(in: CGRect(
            x: point.x - 6,
            y: point.y - 6,
            width: 12,
            height: 12
        ))
        
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(2.0)
        context?.strokeEllipse(in: CGRect(
            x: point.x - 6,
            y: point.y - 6,
            width: 12,
            height: 12
        ))
    }
    
    // MARK: - GPX Export
    func exportToGPX(route: DriveRoute) -> Data? {
        let coordinates = route.coordinates
        guard !coordinates.isEmpty else { return nil }
        
        var gpxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Motor Mates" xmlns="http://www.topografix.com/GPX/1/1">
        <metadata>
        <name>\(route.name.xmlEscaped)</name>
        <desc>\(route.routeDescription.xmlEscaped)</desc>
        <time>\(ISO8601DateFormatter().string(from: route.createdAt))</time>
        </metadata>
        <trk>
        <name>\(route.name.xmlEscaped)</name>
        <desc>\(route.routeDescription.xmlEscaped)</desc>
        <trkseg>
        """
        
        for coordinate in coordinates {
            gpxContent += """
            <trkpt lat="\(coordinate.latitude)" lon="\(coordinate.longitude)">
            </trkpt>
            """
        }
        
        gpxContent += """
        </trkseg>
        </trk>
        """
        
        // Add waypoints
        for waypoint in route.routeWaypoints {
            gpxContent += """
            <wpt lat="\(waypoint.coordinate.latitude)" lon="\(waypoint.coordinate.longitude)">
            <name>\(waypoint.name.xmlEscaped)</name>
            <desc>\(waypoint.waypointDescription.xmlEscaped)</desc>
            <type>\(waypoint.waypointType.rawValue.xmlEscaped)</type>
            </wpt>
            """
        }
        
        gpxContent += "</gpx>"
        
        return gpxContent.data(using: .utf8)
    }
    
    // MARK: - Deep Link Handling
    func handleIncomingURL(_ url: URL) -> String? {
        // Extract route share ID from URL
        // Expected format: https://motormates.app/routes/{shareID}
        let pathComponents = url.pathComponents
        
        guard pathComponents.count >= 3,
              pathComponents[1] == "routes" else {
            return nil
        }
        
        return pathComponents[2]
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Share Content Model
struct ShareContent {
    let route: DriveRoute
    let shareURL: URL
    let shareText: String
    let mapImage: UIImage?
}

// MARK: - String Extension for XML Escaping
extension String {
    var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Share Sheet View
struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    let completion: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Enhanced Share Route View
struct EnhancedShareRouteView: View {
    let route: DriveRoute
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareService = ShareService.shared
    
    @State private var shareContent: ShareContent?
    @State private var isGeneratingContent = false
    @State private var showingShareSheet = false
    @State private var showingGPXExport = false
    @State private var gpxData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGeneratingContent {
                    loadingView
                } else if let content = shareContent {
                    shareContentView(content)
                } else {
                    Button("Generate Share Link") {
                        generateShareContent()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Share Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let content = shareContent {
                ShareSheetView(
                    items: [content.shareText, content.shareURL],
                    completion: { dismiss() }
                )
            }
        }
        .fileExporter(
            isPresented: $showingGPXExport,
            document: GPXDocument(data: gpxData ?? Data()),
            contentType: .xml,
            defaultFilename: "\(route.name).gpx"
        ) { result in
            switch result {
            case .success:
                // GPX exported successfully
                break
            case .failure(let error):
                print("GPX export failed: \(error)")
            }
        }
        .onAppear {
            generateShareContent()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating share content...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func shareContentView(_ content: ShareContent) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Map Preview
            if let mapImage = content.mapImage {
                Image(uiImage: mapImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            }
            
            // Share Text Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Share Preview")
                    .font(.headline)
                
                Text(content.shareText)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Share Options
            VStack(spacing: 12) {
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Link")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: exportGPX) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Export GPX File")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                Button(action: copyLink) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Link")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
    }
    
    private func generateShareContent() {
        isGeneratingContent = true
        
        Task {
            shareContent = await shareService.createShareContent(for: route)
            isGeneratingContent = false
        }
    }
    
    private func exportGPX() {
        gpxData = shareService.exportToGPX(route: route)
        showingGPXExport = true
    }
    
    private func copyLink() {
        if let content = shareContent {
            UIPasteboard.general.string = content.shareURL.absoluteString
        }
    }
}

// MARK: - GPX Document
struct GPXDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.xml] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview
#Preview {
    let route = DriveRoute(name: "Pacific Coast Highway")
    route.routeDescription = "A scenic coastal drive with breathtaking ocean views"
    route.distance = 280.5
    route.estimatedDuration = 360
    route.difficulty = .moderate
    route.category = .scenic
    
    return EnhancedShareRouteView(route: route)
        .modelContainer(for: DriveRoute.self, inMemory: true)
}