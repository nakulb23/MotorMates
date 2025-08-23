import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main Map View for Drives
struct DriveMapView: UIViewRepresentable {
    @Binding var route: DriveRoute?
    @Binding var isEditing: Bool
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    
    let onRouteUpdated: ([CLLocationCoordinate2D]) -> Void
    let onWaypointAdded: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // Add gesture recognizers for route editing
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        
        // Update route display
        updateRouteDisplay(mapView)
        
        // Update editing state
        mapView.isUserInteractionEnabled = true
        
        // Update region if needed
        if let route = route, let region = route.region {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateRouteDisplay(_ mapView: MKMapView) {
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        guard let route = route else { return }
        
        let coordinates = route.coordinates
        guard coordinates.count > 1 else { return }
        
        // Add route polyline
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // Add waypoint annotations
        for waypoint in route.routeWaypoints {
            let annotation = WaypointAnnotation(waypoint: waypoint)
            mapView.addAnnotation(annotation)
        }
        
        // Add landmark annotations
        for landmark in route.landmarks {
            let annotation = LandmarkAnnotation(landmark: landmark)
            mapView.addAnnotation(annotation)
        }
        
        // Add start/end annotations
        if let start = coordinates.first {
            let startAnnotation = RoutePointAnnotation(coordinate: start, type: .start)
            mapView.addAnnotation(startAnnotation)
        }
        
        if let end = coordinates.last, coordinates.count > 1 {
            let endAnnotation = RoutePointAnnotation(coordinate: end, type: .end)
            mapView.addAnnotation(endAnnotation)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: DriveMapView
        
        init(_ parent: DriveMapView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard parent.isEditing else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            parent.selectedCoordinate = coordinate
            parent.onWaypointAdded(coordinate)
        }
        
        // MARK: - MKMapViewDelegate
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            
            if let waypointAnnotation = annotation as? WaypointAnnotation {
                return createWaypointAnnotationView(mapView, annotation: waypointAnnotation)
            }
            
            if let landmarkAnnotation = annotation as? LandmarkAnnotation {
                return createLandmarkAnnotationView(mapView, annotation: landmarkAnnotation)
            }
            
            if let routePointAnnotation = annotation as? RoutePointAnnotation {
                return createRoutePointAnnotationView(mapView, annotation: routePointAnnotation)
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle annotation selection for editing
            if parent.isEditing, let coordinate = view.annotation?.coordinate {
                parent.selectedCoordinate = coordinate
            }
        }
        
        private func createWaypointAnnotationView(_ mapView: MKMapView, annotation: WaypointAnnotation) -> MKAnnotationView {
            let identifier = "WaypointAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            view.markerTintColor = UIColor.systemOrange
            view.glyphImage = UIImage(systemName: annotation.waypoint.waypointType.icon)
            view.canShowCallout = true
            
            return view
        }
        
        private func createLandmarkAnnotationView(_ mapView: MKMapView, annotation: LandmarkAnnotation) -> MKAnnotationView {
            let identifier = "LandmarkAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            view.markerTintColor = UIColor.systemPurple
            view.glyphImage = UIImage(systemName: annotation.landmark.landmarkType.icon)
            view.canShowCallout = true
            
            return view
        }
        
        private func createRoutePointAnnotationView(_ mapView: MKMapView, annotation: RoutePointAnnotation) -> MKAnnotationView {
            let identifier = "RoutePointAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            switch annotation.type {
            case .start:
                view.markerTintColor = UIColor.systemGreen
                view.glyphImage = UIImage(systemName: "play.circle.fill")
            case .end:
                view.markerTintColor = UIColor.systemRed
                view.glyphImage = UIImage(systemName: "stop.circle.fill")
            }
            
            view.canShowCallout = true
            return view
        }
    }
}

// MARK: - Custom Annotations
class WaypointAnnotation: NSObject, MKAnnotation {
    let waypoint: RouteWaypoint
    var coordinate: CLLocationCoordinate2D { waypoint.coordinate }
    var title: String? { waypoint.name.isEmpty ? waypoint.waypointType.rawValue : waypoint.name }
    var subtitle: String? { waypoint.waypointDescription.isEmpty ? nil : waypoint.waypointDescription }
    
    init(waypoint: RouteWaypoint) {
        self.waypoint = waypoint
    }
}

class LandmarkAnnotation: NSObject, MKAnnotation {
    let landmark: DriveLandmark
    var coordinate: CLLocationCoordinate2D { landmark.location }
    var title: String? { landmark.name }
    var subtitle: String? { landmark.landmarkDescription.isEmpty ? landmark.landmarkType.rawValue : landmark.landmarkDescription }
    
    init(landmark: DriveLandmark) {
        self.landmark = landmark
    }
}

class RoutePointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let type: RoutePointType
    var title: String? { type.rawValue }
    
    enum RoutePointType: String {
        case start = "Start"
        case end = "End"
    }
    
    init(coordinate: CLLocationCoordinate2D, type: RoutePointType) {
        self.coordinate = coordinate
        self.type = type
    }
}

// MARK: - SwiftUI Map View Wrapper
struct DriveMapContainer: View {
    @Binding var route: DriveRoute?
    @State private var isEditing = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingWaypointSheet = false
    @State private var editingCoordinates: [CLLocationCoordinate2D] = []
    
    var body: some View {
        ZStack {
            DriveMapView(
                route: $route,
                isEditing: $isEditing,
                selectedCoordinate: $selectedCoordinate,
                onRouteUpdated: { coordinates in
                    editingCoordinates = coordinates
                    route?.updateRoute(coordinates: coordinates, waypoints: route?.routeWaypoints ?? [])
                },
                onWaypointAdded: { coordinate in
                    selectedCoordinate = coordinate
                    showingWaypointSheet = true
                }
            )
            
            // Map Controls
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Edit Mode Toggle
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(isEditing ? Color.green : Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        // Center on Route
                        if let route = route, route.coordinates.count > 0 {
                            Button(action: {
                                // This would trigger the map to center on the route
                                // Implementation would need coordination with the map view
                            }) {
                                Image(systemName: "location.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingWaypointSheet) {
            if let coordinate = selectedCoordinate {
                WaypointCreationSheet(
                    coordinate: coordinate,
                    onSave: { waypoint in
                        // Add waypoint to route
                        if var currentRoute = route {
                            let currentWaypoints = currentRoute.routeWaypoints
                            let updatedWaypoints = currentWaypoints + [waypoint]
                            currentRoute.updateRoute(coordinates: currentRoute.coordinates, waypoints: updatedWaypoints)
                        }
                        showingWaypointSheet = false
                    },
                    onCancel: {
                        showingWaypointSheet = false
                    }
                )
            }
        }
    }
}

// MARK: - Waypoint Creation Sheet
struct WaypointCreationSheet: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (RouteWaypoint) -> Void
    let onCancel: () -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType = WaypointType.custom
    
    var body: some View {
        NavigationView {
            Form {
                Section("Waypoint Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Type") {
                    Picker("Waypoint Type", selection: $selectedType) {
                        ForEach(WaypointType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section("Location") {
                    HStack {
                        Text("Latitude:")
                        Spacer()
                        Text("\(coordinate.latitude, specifier: "%.6f")")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Longitude:")
                        Spacer()
                        Text("\(coordinate.longitude, specifier: "%.6f")")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let waypoint = RouteWaypoint(
                            coordinate: coordinate,
                            name: name,
                            waypointDescription: description,
                            waypointType: selectedType
                        )
                        onSave(waypoint)
                    }
                    .disabled(name.isEmpty && selectedType == .custom)
                }
            }
        }
    }
}