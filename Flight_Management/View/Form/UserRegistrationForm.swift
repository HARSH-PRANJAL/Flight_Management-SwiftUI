import PhotosUI
import SwiftData
import SwiftUI

struct UserRegistrationForm: View {
    @Environment(\.modelContext) var context
    @Environment(SessionManager.self) var session

    @Binding var isPresented: Bool

    // For edit mode
    @State var editForm: Bool = false
    @State var user: User? = nil

    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordFieldText: String = ""
    @State private var selectedRole: UserRole? = nil

    @State var selectedPhoto: PhotosPickerItem?
    @State var photoData: Data?
    @State var profilePreview: Image?

    @FocusState private var focusState: FormFocus?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ProfilePhotoField(
                        selectedPhoto: $selectedPhoto,
                        profilePreview: $profilePreview,
                        onChangeAction: { item in
                            await processPhoto(item)
                        }
                    )
                    userNameField.disabled(editForm)
                    passwordField
                    confirmPasswordField
                    rolePicker.disabled(editForm)

                    registerButton
                }
                .onAppear {
                    if editForm {
                        password = ""
                        confirmPassword = ""
                        passwordFieldText = ""
                    } else {
                        password = user?.password ?? ""
                        confirmPassword = user?.password ?? ""
                        passwordFieldText = user?.password ?? ""
                    }

                    if let imageData = user?.profileImage,
                        let uiImage = UIImage(data: imageData)
                    {
                        profilePreview = Image(uiImage: uiImage)
                    }

                    if let user = user {
                        name = user.name
                        selectedRole = user.role
                    }
                }
                .navigationTitle("User registration")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
                Spacer()
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if session.isLoggedIn {
                    user = session.getUserFromDB(modelContext: context)
                    name = user?.name ?? ""
                    selectedRole = user?.role ?? nil
                    editForm = true
                }
            }
        }
    }
}

// MARK: UI
extension UserRegistrationForm {

    var userNameField: some View {
        FormInputField(
            label: "Username",
            placeholder: "Enter your name",
            focus: .name,
            hasError: false,
            maxLength: 100,
            allowedCharacter: {
                $0.isLetter || $0.isNumber || $0.isWhitespace || $0 == "."
            },
            trimWhitespace: true,
            text: $name,
            focusedField: $focusState
        )
        .onChange(of: name) { oldValue, newValue in
            if newValue.count > 100 {
                name = String(newValue.prefix(100))
                return
            }

            var allowed = newValue.allSatisfy {
                $0.isLetter || $0.isNumber
                    || $0.isWhitespace
            }

            if !allowed {
                name = newValue.filter {
                    $0.isLetter || $0.isNumber
                        || $0.isWhitespace
                }
            }

            allowed = newValue.allSatisfy(\.isWhitespace)
            if allowed {
                name = ""
            }
        }
    }

    var confirmPasswordField: some View {
        FormInputField(
            label: "Confirm Password",
            placeholder: "Repeat your password",
            focus: .confirmPassword,
            hasError: !confirmPassword.isEmpty && confirmPassword != password,
            maxLength: 100,
            text: $confirmPassword,
            focusedField: $focusState
        )
    }

    var passwordField: some View {
        FormInputField(
            label: "Password",
            placeholder: "Enter your password",
            focus: .password,
            hasError: false,
            maxLength: 100,
            text: $passwordFieldText,
            focusedField: $focusState
        )
        .onAppear {
            passwordFieldText = password
        }
        .onChange(of: passwordFieldText) { _, newValue in
            if focusState == .password {
                password = newValue
            }
        }
        .onChange(of: focusState) { _, newVal in
            if newVal == .password {
                passwordFieldText = password
            } else {
                passwordFieldText = String(
                    repeating: "*",
                    count: password.count
                )
            }
        }
    }

    var rolePicker: some View {
        FormPickerField<UserRole>(
            label: "Role",
            placeholder: "User role",
            focus: .role,
            hasError: false,
            selection: $selectedRole,
            focusedField: $focusState
        )
    }

    var registerButton: some View {
        Button(action: {
            if editForm {
                handleUpdateUser()
            } else {
                handleRegister()
            }
        }) {
            Text(editForm ? "Update" : "Register")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isFormValid
                        ? Color(.systemGreen) : Color(.systemGreen).opacity(0.7)
                )
                .cornerRadius(12)
        }
        .disabled(!isFormValid)
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var isFormValid: Bool {
        let hasValidPasswordForCreation =
            !password.isEmpty && password == confirmPassword
        let hasValidPasswordForEdit =
            password.isEmpty
            || (password == confirmPassword && !password.isEmpty)

        if editForm {
            return hasValidPasswordForEdit
        } else {
            return !name.isEmpty && hasValidPasswordForCreation
                && selectedRole != nil
        }
    }
}

//MARK: Util
extension UserRegistrationForm {
    func processPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self)
            else { return }
            profilePreview = handleImageData(data, photo: &(photoData))
        } catch {
            print("Photo loading failed: \(error.localizedDescription)")
        }
    }

    private func handleRegister() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let newUser = User(
            name: trimmedName,
            password: password,
            role: selectedRole!,
            profileImage: photoData
        )
        context.insert(newUser)

        do {
            try context.save()
            withAnimation(.easeOut) {
                isPresented = false
            }
        } catch {
            //            errorMessage = "Unable to save user."
        }
    }

    private func handleUpdateUser() {
        guard let targetUser = user else { return }

        if !password.isEmpty {
            targetUser.password = password
        }
        if let newPhotoData = photoData {
            targetUser.profileImage = newPhotoData
        }

        do {
            try context.save()
            if session.user?.id == targetUser.id.uuidString {
                session.loginUser(targetUser)
            }
            withAnimation(.easeOut) {
                isPresented = false
            }
        } catch {
            print("Failed to update user: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var shown = true
    return UserRegistrationForm(isPresented: $shown)
        .modelContainer(for: User.self, inMemory: true)
}
