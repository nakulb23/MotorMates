import SwiftUI
import SwiftData
import MapKit
import PhotosUI

// MARK: - Create Route View
struct CreateRouteView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var route = DriveRoute(name: "")
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var currentStep: CreationStep = .details
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingGPXImporter = false
    @State private var showingAuth = false
    
    enum CreationStep: CaseIterable {
        case details, route, photos, review
        
        var title: String {
            switch self {
            case .details: return "Route Details"
            case .route: return "Plot Route"
            case .photos: return "Add Photos"
            case .review: return "Review & Save"
            }
        }
        
        var icon: String {
            switch self {
            case .details: return "info.circle"
            case .route: return "map"
            case .photos: return "camera"
            case .review: return "checkmark.circle"
            }
        }
    }
    
    var body: some View {
        if authService.currentUser != nil {
            createRouteContent
        } else {
            authRequiredView
        }
    }
    
    private var authRequiredView: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Create Route")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Create an account to save and share your driving routes with other automotive enthusiasts")
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
    
    private var createRouteContent: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                progressIndicator
                
                // Step Content
                TabView(selection: $currentStep) {
                    ForEach(CreationStep.allCases, id: \.self) { step in
                        stepContent(for: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation Buttons
                navigationButtons
            }
            .navigationTitle("Create Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // Step indicators
            HStack(spacing: 0) {
                ForEach(Array(CreationStep.allCases.enumerated()), id: \.1) { index, step in
                    HStack(spacing: 0) {
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(stepColor(for: step))
                                .frame(width: 32, height: 32)
                            
                            if isStepCompleted(step) {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(currentStep == step ? .white : .secondary)
                            }
                        }
                        
                        // Connecting line
                        if index < CreationStep.allCases.count - 1 {
                            Rectangle()
                                .fill(isStepCompleted(step) ? Color.accentColor : Color(.systemGray4))
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Current step title
            Text(currentStep.title)
                .font(.headline)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private func stepContent(for step: CreationStep) -> some View {
        switch step {
        case .details:
            routeDetailsStep
        case .route:
            routePlottingStep
        case .photos:
            photosStep
        case .review:
            reviewStep
        }
    }
    
    // MARK: - Route Details Step
    private var routeDetailsStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Basic Information")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Route Name", text: $route.name)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Description", text: $route.routeDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Route Characteristics")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(RouteCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        route.category = category
                                    }) {
                                        HStack {
                                            Image(systemName: category.icon)
                                            Text(category.rawValue)
                                                .font(.caption)
                                            Spacer()
                                        }
                                        .foregroundColor(route.category == category ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(route.category == category ? Color.accentColor : Color(.systemGray5))
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Difficulty
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Difficulty")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 8) {
                                ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                                    Button(action: {
                                        route.difficulty = difficulty
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: difficulty.icon)
                                                .font(.caption)
                                                .foregroundColor(route.difficulty == difficulty ? .white : Color(difficulty.color))
                                            
                                            Text(difficulty.shortName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(route.difficulty == difficulty ? .white : .primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(route.difficulty == difficulty ? Color(difficulty.color) : Color(.systemGray5))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Best Season
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best Season")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Best Season", selection: $route.bestSeason) {
                                ForEach(BestSeason.allCases, id: \.self) { season in
                                    HStack {
                                        Image(systemName: season.icon)
                                        Text(season.rawValue)
                                    }
                                    .tag(season)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Route Plotting Step
    private var routePlottingStep: some View {
        VStack(spacing: 0) {
            // Instructions
            VStack(spacing: 8) {
                Text("Plot Your Route")
                    .font(.headline)
                
                Text("Tap on the map to add waypoints and create your route")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Map
            ZStack {
                DriveMapContainer(route: .constant(route))
                
                VStack {
                    Spacer()
                    
                    HStack {
                        // Import GPX Button
                        Button(action: {
                            showingGPXImporter = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Import GPX")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Clear Route Button
                        if !routeCoordinates.isEmpty {
                            Button(action: {
                                routeCoordinates.removeAll()
                                route.updateRoute(coordinates: [], waypoints: [])
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear")
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .fileImporter(
            isPresented: $showingGPXImporter,
            allowedContentTypes: [.xml],
            onCompletion: handleGPXImport
        )
    }
    
    // MARK: - Photos Step
    private var photosStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Add Photos")
                    .font(.headline)
                
                Text("Add photos from your drive to share the experience")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Photo Grid
            if route.photos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No photos added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingPhotoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Photos")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        // Add Photo Button
                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text("Add")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                        
                        // Photo Thumbnails
                        ForEach(route.photos) { photo in
                            AsyncImage(url: photo.photoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                    .cornerRadius(8)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .aspectRatio(1, contentMode: .fit)
                                    .cornerRadius(8)
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Review Step
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Route Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Route Summary")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Name:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(route.name)
                                .foregroundColor(.secondary)
                        }
                        
                        if !route.routeDescription.isEmpty {
                            HStack(alignment: .top) {
                                Text("Description:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(route.routeDescription)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        HStack {
                            Text("Category:")
                                .fontWeight(.medium)
                            Spacer()
                            HStack {
                                Image(systemName: route.category.icon)
                                Text(route.category.rawValue)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Difficulty:")
                                .fontWeight(.medium)
                            Spacer()
                            HStack {
                                Image(systemName: route.difficulty.icon)
                                    .foregroundColor(Color(route.difficulty.color))
                                Text(route.difficulty.rawValue)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Best Season:")
                                .fontWeight(.medium)
                            Spacer()
                            HStack {
                                Image(systemName: route.bestSeason.icon)
                                Text(route.bestSeason.rawValue)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Route Stats
                if route.distance > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Route Statistics")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            StatItem(
                                icon: "road.lanes",
                                value: String(format: "%.1f km", route.distance),
                                label: "Distance"
                            )
                            
                            StatItem(
                                icon: "clock",
                                value: formatDuration(route.estimatedDuration),
                                label: "Est. Duration"
                            )
                            
                            if let elevation = route.elevationGain {
                                StatItem(
                                    icon: "mountain.2",
                                    value: String(format: "%.0f m", elevation),
                                    label: "Elevation"
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Photos Summary
                if !route.photos.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photos (\(route.photos.count))")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(route.photos.prefix(5)) { photo in
                                    AsyncImage(url: photo.photoURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipped()
                                            .cornerRadius(8)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                if route.photos.count > 5 {
                                    Text("+\(route.photos.count - 5)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, height: 60)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack {
            // Previous Button
            if currentStep != .details {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            // Next/Save Button
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == .review ? "Save Route" : "Next")
                    if currentStep != .review {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(canProceed ? Color.accentColor : Color.gray)
                .cornerRadius(8)
            }
            .disabled(!canProceed)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Methods
    private func stepColor(for step: CreationStep) -> Color {
        if isStepCompleted(step) {
            return .accentColor
        } else if currentStep == step {
            return .accentColor
        } else {
            return Color(.systemGray4)
        }
    }
    
    private func isStepCompleted(_ step: CreationStep) -> Bool {
        switch step {
        case .details:
            return !route.name.isEmpty
        case .route:
            return route.coordinates.count > 1
        case .photos:
            return true // Photos are optional
        case .review:
            return false // Never completed until saved
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .details:
            return !route.name.isEmpty
        case .route:
            return route.coordinates.count > 1
        case .photos:
            return true
        case .review:
            return true
        }
    }
    
    private func previousStep() {
        withAnimation {
            if let currentIndex = CreationStep.allCases.firstIndex(of: currentStep),
               currentIndex > 0 {
                currentStep = CreationStep.allCases[currentIndex - 1]
            }
        }
    }
    
    private func nextStep() {
        withAnimation {
            if currentStep == .review {
                saveRoute()
            } else if let currentIndex = CreationStep.allCases.firstIndex(of: currentStep),
                      currentIndex < CreationStep.allCases.count - 1 {
                currentStep = CreationStep.allCases[currentIndex + 1]
            }
        }
    }
    
    private func saveRoute() {
        modelContext.insert(route)
        try? modelContext.save()
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func handleGPXImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Import GPX file
            // This would be implemented to parse GPX and extract coordinates
            print("GPX import from: \(url)")
        case .failure(let error):
            print("GPX import failed: \(error)")
        }
    }
    
    private func processSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        for photo in photos {
            if let data = try? await photo.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Save photo and create DrivePhoto model
                let fileName = "\(UUID().uuidString).jpg"
                // Save to documents directory
                // Create DrivePhoto and add to route
                let drivePhoto = DrivePhoto(fileName: fileName)
                route.addPhoto(drivePhoto)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CreateRouteView()
        .modelContainer(for: DriveRoute.self, inMemory: true)
}