import SwiftUI

struct GarageView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var cars: [Car] = []
    @State private var showingAddCar = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if cars.isEmpty {
                    EmptyGarageView()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(cars) { car in
                            CarCardView(car: car)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("My Garage")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        showingAddCar = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .refreshable {
                await loadCars()
            }
        }
        .sheet(isPresented: $showingAddCar) {
            AddCarView()
        }
        .task {
            await loadCars()
        }
    }
    
    private func loadCars() async {
        isLoading = true
        // TODO: Load cars from database/storage
        // For now, this will show empty state
        isLoading = false
    }
}

struct CarCardView: View {
    let car: Car
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Car image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "car.side.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("\(car.year) \(car.make) \(car.model)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                )
            
            // Car details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(car.year) \(car.make) \(car.model)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if car.isProject {
                        Text("PROJECT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Engine")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(car.engine)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Horsepower")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(car.horsepower) HP")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(car.color)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                if !car.modifications.isEmpty {
                    Text("Modifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(car.modifications, id: \.self) { mod in
                            Text(mod)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EmptyGarageView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.garage")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Your garage is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Add your first car to start building your collection!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
}

struct AddCarView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var color = ""
    @State private var engine = ""
    @State private var horsepower = ""
    @State private var isProject = false
    @State private var showingAuth = false
    
    var body: some View {
        if authService.currentUser != nil {
            addCarContent
        } else {
            authRequiredView
        }
    }
    
    private var authRequiredView: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Add Your Car")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Create an account to add cars to your garage and track your automotive collection")
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
    
    private var addCarContent: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach(1960...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    
                    TextField("Color", text: $color)
                }
                
                Section("Performance") {
                    TextField("Engine", text: $engine)
                    TextField("Horsepower", text: $horsepower)
                        .keyboardType(.numberPad)
                }
                
                Section("Status") {
                    Toggle("Project Car", isOn: $isProject)
                }
            }
            .navigationTitle("Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCar()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
        }
    }
    
    private func saveCar() {
        // TODO: Save car to database/storage
        dismiss()
    }
}

// MARK: - Car Model
struct Car: Identifiable, Codable {
    let id = UUID()
    let make: String
    let model: String
    let year: Int
    let color: String
    let engine: String
    let horsepower: Int
    let images: [String]
    let isProject: Bool
    let modifications: [String]
}

#Preview {
    GarageView()
}