import PhotosUI
import SwiftUI
import SwiftData

struct StaffRegistrationForm: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    // form fields
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var gender: Gender? = nil
    @State private var role: StaffRole? = nil
    @State private var day: String = ""
    @State private var month: String = ""
    @State private var year: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data? = nil
    @State private var profilePreview: Image? = nil
    @State private var dob: Date? = nil
    
    // validators and errors
    @State private var error: Error = .none
    @State private var errorMessage: String = ""
    @State private var submissionState: SubmissionState = .none

    // ui
    @FocusState private var focusedField: Focus?
    
    // formData
    private let years = Array(
        (Calendar.current.component(.year, from: Date()) - 66)...(Calendar
            .current.component(.year, from: Date()) - 16)
    ).reversed().map { "\($0)" }


    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            ScrollView {
                VStack(spacing: 0) {
                    // profile picture section
                    VStack(spacing: 12) {
                        profilePictureField()
                        Text("Add Photo")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.systemGray))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // name, email, gender & staff role
                    VStack(spacing: 20) {
                        ZStack {
                            customTextField(
                                fieldName: "Name",
                                placeholder: "Enter your full name",
                                field: $name,
                                focus: .name
                            )
                            errorMessage(errorState: $error,for: .name, focusedField: .name ,errorMessage)
                        }
                        
                        
                        ZStack {
                            customTextField(
                                fieldName: "Email",
                                placeholder: "example@example.com",
                                field: $email,
                                focus: .email
                            )
                            errorMessage(errorState: $error, for: .email, focusedField: .email ,errorMessage)
                        }

                        ZStack {
                            genderField()
                            errorMessage(errorState: $error, for: .gender, focusedField: .gender ,errorMessage)
                        }
                        
                        ZStack {
                            designationField()
                            errorMessage(errorState: $error, for: .role, focusedField: .role ,errorMessage)
                        }

                        ZStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date of Birth")
                                    .formFieldLabel()
                                
                                HStack(spacing: 8) {
                                    menuWithButtonSelector(
                                        menuOptions: days,
                                        selection: $day,
                                        placeholder: "Day"
                                    )
                                    menuWithButtonSelector(
                                        menuOptions: Array(Month.allCases).map(
                                            \.rawValue
                                        ),
                                        selection: $month,
                                        placeholder: "Month"
                                    )
                                    menuWithButtonSelector(
                                        menuOptions: years,
                                        selection: $year,
                                        placeholder: "Year"
                                    )
                                }
                            }
                            errorMessage(errorState: $error, for: .dateOfBirth, focusedField: .dateOfBirth, errorMessage)
                        }
                    }
                    .padding(.horizontal, 16)

                    Button(action: {
                        registerStaff()
                    }) {
                        Text("Register")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Text(
                        "Your information will be used for staff identification and internal records only."
                    )
                    .font(.system(size: 13))
                    .foregroundColor(Color(.systemGray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                }
                .navigationTitle("Staff Registration")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .overlay(alignment: .top) {
            if submissionState == .success {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text("Staff added successfully")
                        .foregroundStyle(.white)
                }
                .padding()
                .background(Color.green.opacity(0.9))
                .clipShape(Capsule())
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        submissionState = .none
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: UI Components
extension StaffRegistrationForm {
    
    @ViewBuilder
    private func errorMessage(errorState: Binding<Error>, for error: Error, focusedField: Focus,  _ errorMessage: String) -> some View {
        Text(errorMessage)
            .font(.caption)
            .foregroundStyle(Color(.systemRed))
            .opacity(errorState.wrappedValue == error && self.focusedField != focusedField ? 1 : 0)
            .offset(x:20, y:50)
    }

    @ViewBuilder
    private func menuWithButtonSelector(
        menuOptions: [String],
        selection: Binding<String>,
        placeholder: String = ""
    ) -> some View {
        Menu {
            ForEach(menuOptions, id: \.self) { y in
                Button(y) {
                    selection.wrappedValue = y
                }
            }
        } label: {
            HStack {
                Text(
                    selection.wrappedValue.isEmpty
                        ? placeholder : selection.wrappedValue
                )
                .font(.system(size: 17))
                .foregroundColor(
                    selection.wrappedValue.isEmpty
                        ? Color(.systemGray3) : Color(.label)
                )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    @ViewBuilder
    private func enumMenuProvider<T>(
        selection: Binding<T?>,
        placeholder: String,
        focus: Focus,
        focusedField: FocusState<Focus?>.Binding
    ) -> some View where T: CaseIterable & RawRepresentable & Hashable,
                          T.RawValue == String {

        Menu {
            ForEach(Array(T.allCases), id: \.self) { value in
                Button(value.rawValue) {
                    selection.wrappedValue = value
                }
            }
        } label: {
            HStack {
                Text(selection.wrappedValue?.rawValue ?? placeholder)
                    .font(.system(size: 17))
                    .foregroundColor(
                        selection.wrappedValue == nil
                            ? Color(.systemGray3)
                            : Color(.label)
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .stroke(
                        Color(
                            focusedField.wrappedValue == focus
                                ? .systemBlue
                                : .systemGray3
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .focused(focusedField, equals: focus)
    }

    @ViewBuilder
    private func designationField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Designation")
                .formFieldLabel()
            enumMenuProvider(selection: $role, placeholder: "Designation", focus: .role, focusedField: $focusedField)
        }

            
    }

    @ViewBuilder
    private func genderField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender")
                .font(.callout)
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray))
                .padding(.leading, 4)

            enumMenuProvider(selection: $gender, placeholder: "Gender", focus: .gender, focusedField: $focusedField)
        }
    }

    @ViewBuilder
    private func customTextField(
        fieldName: String,
        placeholder: String,
        field: Binding<String>,
        focus: Focus
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(fieldName)
                .font(.callout)
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray))
                .padding(.leading, 4)

            TextField(placeholder, text: field)
                .font(.system(size: 17))
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .stroke(
                            Color(
                                focusedField == focus
                                    ? .systemBlue : .systemGray3
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: Color.black.opacity(0.07),
                    radius: 2,
                    x: 0,
                    y: 2
                )
                .focused($focusedField, equals: focus)
        }
    }

    @ViewBuilder
    func profilePictureField() -> some View {
        HStack(alignment: .center) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack(alignment: .bottomTrailing) {
                    if let preview = profilePreview {
                        preview
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        Color.gray.opacity(0.4),
                                        lineWidth: 2
                                    )
                            }
                            .shadow(radius: 2)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(.gray.opacity(0.6))
                            .overlay {
                                Circle()
                                    .stroke(
                                        Color.gray.opacity(0.3),
                                        lineWidth: 2
                                    )
                            }
                    }
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.white, .blue)
                        .background(Circle().fill(.white))
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                        .offset(x: 6, y: 6)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let item = newItem else { return }
            Task {
                await imageConverter(item: item)
            }
        }
    }
}

// MARK: Util
extension StaffRegistrationForm {
    
    private var days: [String] {
        return Array(1...Month.numberOfDays(inMonth: month)).map(\.description)
    }
    
    private var createDob: Date? {
        var component = DateComponents()
        component.day = Int(day)
        component.month = Int(month)
        component.year = Int(year)
        
        return Calendar.current.date(from: component)
    }
    
    private enum SubmissionState {
        case success
        case none
        case error
    }

    private enum Error: Equatable {
        case none
        case name
        case email
        case gender
        case role
        case dateOfBirth
    }
    
    private enum Focus: Hashable {
        case name
        case email
        case gender
        case role
        case dateOfBirth
    }
    
    func resetFields() {
        name = ""
        role = .none
        email = ""
        gender = .none
        day = ""
        month = ""
        year = ""
    }

    func imageConverter(item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data),
                    let compressed = image.jpegData(compressionQuality: 0.78)
                {

                    await MainActor.run {
                        self.photoData = compressed
                        self.profilePreview = Image(
                            uiImage: UIImage(data: compressed) ?? image
                        )
                    }
                } else {
                    await MainActor.run {
                        self.photoData = data
                        if let uiImage = UIImage(data: data) {
                            self.profilePreview = Image(uiImage: uiImage)
                        }
                    }
                }
            }
        } catch {
            print("Photo loading failed: \(error.localizedDescription)")
        }
    }
}

// MARK: Validators
extension StaffRegistrationForm {
    
    private func nameValidation() -> Bool {
        let pattern = /^[A-Za-z][A-Za-z0-9 ]+$/
        let rawName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if rawName.isEmpty {
            errorMessage = "Name can not be empty."
            return false
        }
        
        if rawName.wholeMatch(of: pattern) == nil {
            errorMessage = "Provide correct name. eg. John23 Doe"
            return false
        } else {
            name = rawName
            return true
        }
    }
    
    private func emailValidation() -> Bool {
        let pattern = /^[A-Z0-9a-z._%+-]{1,64}@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/
        let rawEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if rawEmail.isEmpty {
            errorMessage = "Email can not be empty."
            return false
        }
        
        if email.wholeMatch(of: pattern) == nil {
            errorMessage = "Provide correct email."
            return false
        }
        if email.count > 254 {
            errorMessage = "Email can not be more than 254 characters long."
            return false
        }
        
        return true
    }
    
    private func dobValidation() -> Bool {
        guard let birthDate = createDob else {
            errorMessage = "Date of birth is required"
            return false
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: today)
        guard let age = ageComponents.year else {
            errorMessage = "Invalid date of birth"
            return false
        }
        
        switch role {
        case .pilot, .coPilot:
            if age > 65 {
                errorMessage = "Maximum age for pilots is 65 years"
                return false
            }
        case .cabinCrew:
            if age > 60 {
                errorMessage = "Maximum age for cabin crew is 60 years"
                return false
            }
        case .none:
            break
        }
        
        dob = birthDate
        
        return true
    }
    
    private func registerStaff() {
        error = .none
        errorMessage = ""
        
        if !nameValidation() {
            error = .name
        } else if !emailValidation() {
            error = .email
        } else if gender == nil {
            error = .gender
            errorMessage = "Please select a gender."
        } else if role == nil {
            error = .role
            errorMessage = "Please select a staff designation."
        } else if !dobValidation() {
            error = .dateOfBirth
        }
        
        if error != .none {
            return
        }
        
        let newStaff = Staff(name: name, designation: role!, gender: gender!, email: email, profileImage: photoData)
        
        
        do {
            context.insert(newStaff)
            try context.save()
            submissionState = .success
            resetFields()
        } catch {
            submissionState = .error
            errorMessage = "Something went wrong. Please try again later."
        }
        
    }
}

#Preview {
    StaffRegistrationForm()
        .modelContainer(for: Staff.self, inMemory: true)
}
