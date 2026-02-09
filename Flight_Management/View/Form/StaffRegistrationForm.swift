import PhotosUI
import SwiftUI

struct StaffRegistrationForm: View {

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

    @FocusState private var focusedField: Focus?

    private var days: [String] {
        return Array(1...Month.numberOfDays(inMonth: month)).map(\.description)
    }

    let years = Array(
        (Calendar.current.component(.year, from: Date()) - 100)...(Calendar
            .current.component(.year, from: Date()))
    ).reversed().map { "\($0)" }

    private enum Focus: Hashable {
        case name
        case email
        case gender
        case role
    }

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
                        customTextField(
                            fieldName: "Name",
                            placeholder: "Enter your full name",
                            field: $name,
                            focus: .name
                        )

                        customTextField(
                            fieldName: "Email",
                            placeholder: "example@example.com",
                            field: $email,
                            focus: .email
                        )

                        genderField()
                        designationField()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.callout)
                                .font(.system(size: 15))
                                .foregroundColor(Color(.systemGray))
                                .padding(.leading, 4)

                            HStack(spacing: 8) {

                                menuWithButtonSelector(
                                    menuOptions: days,
                                    selection: $day
                                )
                                menuWithButtonSelector(
                                    menuOptions: Array(Month.allCases).map(
                                        \.rawValue
                                    ),
                                    selection: $month
                                )
                                menuWithButtonSelector(
                                    menuOptions: years,
                                    selection: $year
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Button(action: {

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
    }
}

// MARK: UI Components
extension StaffRegistrationForm {

    @ViewBuilder
    private func menuWithButtonSelector(
        menuOptions: [String],
        selection: Binding<String>
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
                        ? "Year" : selection.wrappedValue
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
    private func designationField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Designation")
                .font(.callout)
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray))
                .padding(.leading, 4)

            Menu {
                ForEach(StaffRole.allCases, id: \.self) { role in
                    Button(role.rawValue) {
                        self.role = role
                    }
                }
            } label: {
                HStack {
                    Text(
                        role == nil
                            ? "Select gender" : role?.rawValue ?? ""
                    )
                    .font(.system(size: 17))
                    .foregroundColor(
                        role == nil
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
                                focusedField == .role
                                    ? .systemBlue : .systemGray3
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
            .focused($focusedField, equals: .role)
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

            Menu {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Button(gender.rawValue) {
                        self.gender = gender
                    }
                }
            } label: {
                HStack {
                    Text(
                        gender == nil
                            ? "Select gender" : gender?.rawValue ?? ""
                    )
                    .font(.system(size: 17))
                    .foregroundColor(
                        gender == nil
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
                                focusedField == .gender
                                    ? .systemBlue : .systemGray3
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
            .focused($focusedField, equals: .gender)
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

// MARK: UTIL
extension StaffRegistrationForm {

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

#Preview {
    StaffRegistrationForm()
}
