import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var city: String
    @State private var state: String
    @State private var country: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showDatePicker = false
    @State private var hasDateOfBirth: Bool
    
    let user: UserProfile
    
    init(user: UserProfile) {
        self.user = user
        self._name = State(initialValue: user.name)
        self._dateOfBirth = State(initialValue: user.dateOfBirth ?? Date())
        self._city = State(initialValue: user.city)
        self._state = State(initialValue: user.state)
        self._country = State(initialValue: user.country)
        self._hasDateOfBirth = State(initialValue: user.dateOfBirth != nil)
        
        // Load existing profile photo if available
        if let photoURL = user.profilePhotoURL,
           let imageData = try? Data(contentsOf: photoURL) {
            self._profileImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
                                        Text("No Photo")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                // Photo Picker Button
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Text(profileImage == nil ? "Add Photo" : "Change Photo")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .stroke(Color.orange, lineWidth: 1)
                                        )
                                }
                                
                                // Remove Photo Button
                                if profileImage != nil {
                                    Button("Remove") {
                                        profileImage = nil
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(Color.red, lineWidth: 1)
                                    )
                                }
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
                            
                            VStack(spacing: 8) {
                                // Date of Birth Toggle
                                HStack {
                                    Text("Include Date of Birth")
                                        .font(.subheadline)
                                    Spacer()
                                    Toggle("", isOn: $hasDateOfBirth)
                                        .tint(.orange)
                                }
                                
                                // Date of Birth Picker
                                if hasDateOfBirth {
                                    HStack {
                                        Text("Date of Birth")
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: { showDatePicker.toggle() }) {
                                            Text(dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                                                .foregroundColor(.primary)
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
                        }
                    }
                    
                    // Location Information
                    VStack(spacing: 16) {
                        Text("Location")
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
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
        // Save photo if changed
        var photoFileName: String? = user.profilePhotoFileName
        
        if profileImage == nil && user.profilePhotoFileName != nil {
            // Photo was removed
            if let photoURL = user.profilePhotoURL {
                try? FileManager.default.removeItem(at: photoURL)
            }
            photoFileName = nil
        } else if let profileImage = profileImage,
                  let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            // Photo was added or changed
            photoFileName = authService.saveProfilePhoto(imageData)
        }
        
        // Update user profile
        user.updateProfile(
            name: name,
            dateOfBirth: hasDateOfBirth ? dateOfBirth : nil,
            city: city,
            state: state,
            country: country
        )
        
        if photoFileName != user.profilePhotoFileName {
            user.updateProfilePhoto(fileName: photoFileName)
        }
        
        // Update authentication service
        authService.updateProfile(user)
        
        dismiss()
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

#Preview {
    let sampleUser = UserProfile(email: "test@example.com", name: "John Doe")
    EditProfileView(user: sampleUser)
}