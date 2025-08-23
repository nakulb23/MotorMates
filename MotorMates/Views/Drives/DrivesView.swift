import SwiftUI
import SwiftData
import MapKit

// MARK: - Main Drives View
struct DrivesView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DriveRoute.lastModified, order: .reverse) private var routes: [DriveRoute]
    
    @State private var searchText = ""
    @State private var selectedCategory: RouteCategory? = nil
    @State private var selectedDifficulty: DifficultyLevel? = nil
    @State private var showingCreateRoute = false
    @State private var showingFilters = false
    
    var filteredRoutes: [DriveRoute] {
        routes.filter { route in
            let matchesSearch = searchText.isEmpty || 
                route.name.localizedCaseInsensitiveContains(searchText) ||
                route.routeDescription.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || route.category == selectedCategory
            let matchesDifficulty = selectedDifficulty == nil || route.difficulty == selectedDifficulty
            
            return matchesSearch && matchesCategory && matchesDifficulty
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Route List
                if filteredRoutes.isEmpty {
                    emptyStateView
                } else {
                    routeListView
                }
            }
            .navigationTitle("Drives")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        showingCreateRoute = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateRoute) {
            CreateRouteView()
        }
        .sheet(isPresented: $showingFilters) {
            FiltersSheet(
                selectedCategory: $selectedCategory,
                selectedDifficulty: $selectedDifficulty
            )
        }
    }
    
    // MARK: - Search and Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search routes...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Filter Button
                    Button(action: { showingFilters = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.body)
                            Text("Filters")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(20)
                    }
                    
                    // Active Filter Pills
                    if let category = selectedCategory {
                        FilterPill(
                            text: category.shortName,
                            icon: category.icon,
                            onRemove: { selectedCategory = nil }
                        )
                    }
                    
                    if let difficulty = selectedDifficulty {
                        FilterPill(
                            text: difficulty.shortName,
                            icon: difficulty.icon,
                            onRemove: { selectedDifficulty = nil }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Route List View
    private var routeListView: some View {
        List {
            ForEach(filteredRoutes) { route in
                NavigationLink(destination: RouteDetailView(route: route)) {
                    RouteListCard(route: route)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteRoutes)
        }
        .listStyle(.plain)
        .refreshable {
            // Refresh routes if needed
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Routes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Browse driving routes or create your own to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { 
                showingCreateRoute = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Route")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    private func deleteRoutes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredRoutes[index])
            }
        }
    }
}

// MARK: - Route List Card
struct RouteListCard: View {
    let route: DriveRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and rating
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !route.routeDescription.isEmpty {
                        Text(route.routeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Rating
                    if route.personalRating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= route.personalRating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: route.category.icon)
                        Text(route.category.rawValue)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
            
            // Route Stats
            HStack(spacing: 16) {
                // Distance
                StatItem(
                    icon: "road.lanes",
                    value: String(format: "%.1f km", route.distance),
                    label: "Distance"
                )
                
                // Duration
                StatItem(
                    icon: "clock",
                    value: formatDuration(route.estimatedDuration),
                    label: "Duration"
                )
                
                // Difficulty
                StatItem(
                    icon: route.difficulty.icon,
                    value: route.difficulty.rawValue,
                    label: "Difficulty",
                    color: Color(route.difficulty.color)
                )
                
                Spacer()
            }
            
            // Bottom info
            HStack {
                Text("Created \(route.createdAt, format: .dateTime.day().month().year())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if route.timesCompleted > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(route.timesCompleted) time\(route.timesCompleted == 1 ? "" : "s")")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
}

// MARK: - Stat Item Component
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .fontWeight(.medium)
            }
            .font(.caption)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let text: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Filters Sheet
struct FiltersSheet: View {
    @Binding var selectedCategory: RouteCategory?
    @Binding var selectedDifficulty: DifficultyLevel?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(RouteCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: category.icon)
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                    
                                    Text(category.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Color.clear
                                            .frame(height: 12)
                                    }
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCategory == category ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section("Difficulty") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                            Button(action: {
                                selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: difficulty.icon)
                                        .foregroundColor(Color(difficulty.color))
                                        .frame(width: 20)
                                    
                                    Text(difficulty.rawValue)
                                        .font(.body)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    if selectedDifficulty == difficulty {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .foregroundColor(.primary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedDifficulty == difficulty ? Color.accentColor.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                        selectedDifficulty = nil
                    }
                }
                
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
    DrivesView()
        .modelContainer(for: DriveRoute.self, inMemory: true)
}