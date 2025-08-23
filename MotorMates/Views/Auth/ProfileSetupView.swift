import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var country: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showDatePicker = false
    @State private var canSkip = true
    
    let user: UserProfile
    
    init(user: UserProfile) {
        self.user = user
        self._name = State(initialValue: user.name)
        self._city = State(initialValue: user.city)
        self._state = State(initialValue: user.state)
        self._country = State(initialValue: user.country)
        if let dob = user.dateOfBirth {
            self._dateOfBirth = State(initialValue: dob)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Complete Your Profile")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Help other MotorMates get to know you better")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Profile Photo Section
                    VStack(spacing: 16) {
                        Text("Profile Photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            // Photo Display
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 120, height: 120)
                                
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                        Text("Add Photo")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Photo Picker Button
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text(profileImage == nil ? "Add Photo" : "Change Photo")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(Color.orange, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    
                    // Personal Information
                    VStack(spacing: 16) {
                        Text("Personal Information")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(ProfileTextFieldStyle())
                            
                            // Date of Birth
                            HStack {
                                Text("Date of Birth")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: { showDatePicker.toggle() }) {
                                    Text(user.dateOfBirth != nil ? dateOfBirth.formatted(date: .abbreviated, time: .omitted) : "Select Date")
                                        .foregroundColor(user.dateOfBirth != nil ? .primary : .secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .onTapGesture {
                                showDatePicker.toggle()
                            }
                        }
                    }
                    
                    // Location Information
                    VStack(spacing: 16) {
                        Text("Location (Optional)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            TextField("City", text: $city)
                                .textFieldStyle(ProfileTextFieldStyle())
                            
                            TextField("State/Province", text: $state)
                                .textFieldStyle(ProfileTextFieldStyle())
                            
                            TextField("Country", text: $country)
                                .textFieldStyle(ProfileTextFieldStyle())
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: saveProfile) {
                            Text("Complete Setup")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange)
                                )
                        }
                        .disabled(name.isEmpty)
                        
                        if canSkip {
                            Button("Skip for Now") {
                                // Just update with current info
                                saveProfile()
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $dateOfBirth)
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                await loadPhoto(from: newPhoto)
            }
        }
    }
    
    private func saveProfile() {
        // Save photo if selected
        var photoFileName: String?
        if let profileImage = profileImage,
           let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            photoFileName = authService.saveProfilePhoto(imageData)
        }
        
        // Update user profile
        user.updateProfile(
            name: name,
            dateOfBirth: showDatePicker && user.dateOfBirth != nil ? dateOfBirth : user.dateOfBirth,
            city: city,
            state: state,
            country: country
        )
        
        if let photoFileName = photoFileName {
            user.updateProfilePhoto(fileName: photoFileName)
        }
        
        // Update authentication service
        authService.updateProfile(user)
    }
    
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = uiImage
                    }
                }
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Date of Birth",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Date of Birth")
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

// MARK: - Profile Text Field Style
struct ProfileTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
    }
}

#Preview {
    let sampleUser = UserProfile(email: "test@example.com", name: "John Doe")
    ProfileSetupView(user: sampleUser)
}