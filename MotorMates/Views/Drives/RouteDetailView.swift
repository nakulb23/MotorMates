import SwiftUI
import SwiftData
import MapKit
import PhotosUI

// MARK: - Route Detail View
struct RouteDetailView: View {
    @Bindable var route: DriveRoute
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingDeleteAlert = false
    @State private var showingDirections = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Image/Map
                headerMapView
                
                // Route Information
                routeInfoSection
                
                // Statistics
                statisticsSection
                
                // Photos Section
                photosSection
                
                // Landmarks Section
                if !route.landmarks.isEmpty {
                    landmarksSection
                }
                
                // Personal Notes
                personalNotesSection
                
                // Action Buttons
                actionButtonsSection
            }
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Drives")
                            .font(.body)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditView = true }) {
                        Label("Edit Route", systemImage: "pencil")
                    }
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("Share Route", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { route.markAsCompleted() }) {
                        Label("Mark as Completed", systemImage: "checkmark.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Route", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditRouteView(route: route)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareRouteView(route: route)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images
        )
        .onChange(of: selectedPhotos) { _, newPhotos in
            Task {
                await processSelectedPhotos(newPhotos)
            }
        }
        .alert("Delete Route", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRoute()
            }
        } message: {
            Text("Are you sure you want to delete this route? This action cannot be undone.")
        }
        .sheet(isPresented: $showingDirections) {
            DirectionsSheet(route: route)
        }
    }
    
    // MARK: - Header Map View
    private var headerMapView: some View {
        ZStack {
            if let region = route.region {
                Map(coordinateRegion: .constant(region))
                .frame(height: 200)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) {
                    Button(action: { showingDirections = true }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding()
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .cornerRadius(16)
                    .overlay {
                        VStack {
                            Image(systemName: "map")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("No route data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Route Information Section
    private var routeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Information")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                if !route.routeDescription.isEmpty {
                    Text(route.routeDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: route.category.icon)
                        Text(route.category.rawValue)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    
                    // Difficulty
                    HStack(spacing: 4) {
                        Image(systemName: route.difficulty.icon)
                            .foregroundColor(Color(route.difficulty.color))
                        Text(route.difficulty.rawValue)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    // Best Season
                    HStack(spacing: 4) {
                        Image(systemName: route.bestSeason.icon)
                        Text(route.bestSeason.rawValue)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                
                // Rating
                if route.personalRating > 0 {
                    HStack(spacing: 4) {
                        Text("Your Rating:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= route.personalRating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    icon: "road.lanes",
                    title: "Distance",
                    value: String(format: "%.1f km", route.distance),
                    color: .blue
                )
                
                StatCard(
                    icon: "clock",
                    title: "Est. Duration",
                    value: formatDuration(route.estimatedDuration),
                    color: .green
                )
                
                if let elevation = route.elevationGain {
                    StatCard(
                        icon: "mountain.2",
                        title: "Elevation Gain",
                        value: String(format: "%.0f m", elevation),
                        color: .orange
                    )
                }
                
                StatCard(
                    icon: "checkmark.circle",
                    title: "Completed",
                    value: "\(route.timesCompleted) time\(route.timesCompleted == 1 ? "" : "s")",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos (\(route.photos.count))")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingPhotoPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if route.photos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No photos added yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingPhotoPicker = true }) {
                        Text("Add Photos")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(route.photos) { photo in
                            PhotoThumbnail(photo: photo)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Landmarks Section
    private var landmarksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Landmarks (\(route.landmarks.count))")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(route.landmarks) { landmark in
                    LandmarkCard(landmark: landmark)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Personal Notes Section
    private var personalNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Notes")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $route.personalNotes)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Text("Add your thoughts, memories, or tips about this route")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Navigate Button
            Button(action: { showingDirections = true }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Get Directions")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                // Share Button
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Mark as Completed Button
                Button(action: { route.markAsCompleted() }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Completed")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
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
    
    private func processSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        for photo in photos {
            if let data = try? await photo.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Save photo to documents directory
                let fileName = "\(UUID().uuidString).jpg"
                if let photoURL = savePhotoToDocuments(uiImage, fileName: fileName) {
                    let drivePhoto = DrivePhoto(fileName: fileName)
                    route.addPhoto(drivePhoto)
                    try? modelContext.save()
                }
            }
        }
        selectedPhotos.removeAll()
    }
    
    private func savePhotoToDocuments(_ image: UIImage, fileName: String) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8),
              let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let photosDirectory = documentsPath.appendingPathComponent("DrivePhotos")
        try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
        
        return fileURL
    }
    
    private func deleteRoute() {
        modelContext.delete(route)
        try? modelContext.save()
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PhotoThumbnail: View {
    let photo: DrivePhoto
    @State private var showingPhotoDetail = false
    
    var body: some View {
        Button(action: { showingPhotoDetail = true }) {
            AsyncImage(url: photo.photoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(8)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .sheet(isPresented: $showingPhotoDetail) {
            PhotoDetailView(photo: photo)
        }
    }
}

struct LandmarkCard: View {
    let landmark: DriveLandmark
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: landmark.landmarkType.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(landmark.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !landmark.landmarkDescription.isEmpty {
                    Text(landmark.landmarkDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(landmark.landmarkType.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: DrivePhoto
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: photo.photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Directions Sheet
struct DirectionsSheet: View {
    let route: DriveRoute
    @Environment(\.dismiss) private var dismiss
    @State private var showingInMaps = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Route Preview
                if let region = route.region {
                    Map(coordinateRegion: .constant(region))
                    .frame(height: 200)
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Navigation Options")
                        .font(.headline)
                    
                    // Apple Maps Button
                    Button(action: openInAppleMaps) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Apple Maps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Get directions to route start")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Google Maps Button
                    Button(action: openInGoogleMaps) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading) {
                                Text("Google Maps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Navigate the complete route")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Get Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openInAppleMaps() {
        guard let startLocation = route.startLocation else { return }
        
        let placemark = MKPlacemark(coordinate: startLocation)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = route.name
        mapItem.openInMaps()
    }
    
    private func openInGoogleMaps() {
        guard let startLocation = route.startLocation else { return }
        
        let urlString = "comgooglemaps://?daddr=\(startLocation.latitude),\(startLocation.longitude)&directionsmode=driving"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to web Google Maps
            let webURLString = "https://maps.google.com/?daddr=\(startLocation.latitude),\(startLocation.longitude)&directionsmode=driving"
            if let webURL = URL(string: webURLString) {
                UIApplication.shared.open(webURL)
            }
        }
    }
}

// MARK: - Edit Route View (Placeholder)
struct EditRouteView: View {
    @Bindable var route: DriveRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Edit Route - Coming Soon")
            .navigationTitle("Edit Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Route View (Placeholder)
struct ShareRouteView: View {
    let route: DriveRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Share Route - Coming Soon")
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
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DriveRoute.self, configurations: config)
    
    let route = DriveRoute(name: "Pacific Coast Highway")
    route.routeDescription = "A scenic coastal drive with breathtaking ocean views"
    route.distance = 280.5
    route.estimatedDuration = 360
    route.difficulty = .moderate
    route.category = .scenic
    route.personalRating = 5
    
    container.mainContext.insert(route)
    
    return RouteDetailView(route: route)
        .modelContainer(container)
}