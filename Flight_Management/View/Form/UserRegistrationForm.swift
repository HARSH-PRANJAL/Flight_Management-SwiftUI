import PhotosUI
import SwiftData
import SwiftUI

struct UserRegistrationForm: View {
    @Environment(\.modelContext) var context
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager

    @Binding var isPresented: Bool

    @State private var viewModel = UserRegistrationFormViewModel()
    @State var user: User? = nil

    @FocusState private var focusState: FormFocus?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ProfilePhotoField(
                        selectedPhoto: $viewModel.selectedPhoto,
                        profilePreview: $viewModel.profilePreview,
                        onChangeAction: { item in
                            await viewModel.processPhoto(item)
                        }
                    )

                    userNameFieldSection
                    emailFieldSection
                    passwordFieldSection
                    confirmPasswordFieldSection
                    roleFieldSection

                    registerButton
                }
                .navigationTitle(
                    viewModel.isEditMode ? "Edit Profile" : "User Registration"
                )
                .navigationBarTitleDisplayMode(.inline)
                .padding()
                Spacer()
            }
            .scrollIndicators(.hidden)
            .task {
                if session.isLoggedIn {
                    user = await session.getUserFromDB(modelContext: context)
                    if let user = user {
                        viewModel.userToEdit = user
                        viewModel.isEditMode = true
                        await viewModel.loadUserData(user)
                    }
                }
            }
        }
    }
}

// MARK: - UI
extension UserRegistrationForm {

    private var userNameFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Username",
                placeholder: "Enter your name",
                focus: .name,
                hasError: viewModel.fieldErrors[.name] != nil,
                maxLength: 100,
                allowedCharacter: {
                    $0.isLetter || $0.isWhitespace
                },
                text: $viewModel.name,
                focusedField: $focusState
            )
            .disabled(viewModel.isEditMode)
            .onChange(of: viewModel.name) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .name)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.name])
        }
    }

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Email",
                placeholder: "Enter your email",
                focus: .email,
                hasError: viewModel.fieldErrors[.email] != nil,
                maxLength: 255,
                allowedCharacter: {
                    $0.isASCII
                },
                text: $viewModel.email,
                focusedField: $focusState
            )
            .disabled(viewModel.isEditMode)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: viewModel.email) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .email)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.email])
        }
    }

    private var passwordFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Password",
                placeholder: "Enter your password",
                focus: .password,
                hasError: viewModel.fieldErrors[.password] != nil,
                maxLength: 100,
                allowedCharacter: {
                    $0.isASCII
                },
                text: $viewModel.password,
                focusedField: $focusState
            )
            .onChange(of: viewModel.password) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .password)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.password])
        }
    }

    private var confirmPasswordFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Confirm Password",
                placeholder: "Repeat your password",
                focus: .confirmPassword,
                hasError: viewModel.fieldErrors[.confirmPassword] != nil,
                maxLength: 100,
                text: $viewModel.confirmPassword,
                focusedField: $focusState
            )
            .onChange(of: viewModel.confirmPassword) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .confirmPassword)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.confirmPassword])
        }
    }

    private var roleFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormPickerField<UserRole>(
                label: "Role",
                placeholder: "User role",
                focus: .role,
                hasError: viewModel.fieldErrors[.role] != nil,
                selection: $viewModel.selectedRole,
                focusedField: $focusState
            )
            .disabled(viewModel.isEditMode)
            .onChange(of: viewModel.selectedRole) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .role)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.role])
        }
    }

    var registerButton: some View {
        Button(action: {
            if viewModel.validateAll() {
                if viewModel.isEditMode {
                    handleUpdateUser()
                } else {
                    handleRegister()
                }
            }
            viewModel.submissionState =
                viewModel.fieldErrors.isEmpty ? .success : .error
        }) {
            Text(viewModel.isEditMode ? "Update" : "Register")
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
        let hasValidName = !viewModel.name.isEmpty
        let hasValidEmail = !viewModel.email.isEmpty
        let hasValidRole = viewModel.selectedRole != nil

        let hasValidPassword = !viewModel.password.isEmpty

        if viewModel.isEditMode {
            return hasValidPassword
        } else {
            return hasValidName && hasValidEmail && hasValidPassword
                && hasValidRole
        }
    }
}

//MARK: Util
extension UserRegistrationForm {

    private func handleRegister() {
        if !viewModel.checkEmailUniqueness(context: context) {
            return
        }

        let trimmedName = viewModel.name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedEmail = viewModel.email.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()

        let newUser = User(
            name: trimmedName,
            email: trimmedEmail,
            password: viewModel.password,
            role: viewModel.selectedRole!,
            profileImage: viewModel.photoData
        )
        context.insert(newUser)

        do {
            try context.save()
            notificationManager.showSuccess("User registered successfully")
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                withAnimation(.easeOut) {
                    isPresented = false
                }
            }
        } catch {
            notificationManager.showError(
                "Failed to register user. Please try again."
            )
        }
    }

    private func handleUpdateUser() {
        guard let targetUser = viewModel.userToEdit else { return }

        if !viewModel.checkEmailUniqueness(context: context) {
            return
        }

        let trimmedEmail = viewModel.email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        targetUser.email = trimmedEmail

        if !viewModel.password.isEmpty {
            targetUser.password = viewModel.password
        }
        if let newPhotoData = viewModel.photoData {
            targetUser.profileImage = newPhotoData
        }

        do {
            try context.save()
            if session.user?.id == targetUser.id.uuidString {
                session.loginUser(targetUser)
            }
            notificationManager.showSuccess("Profile updated successfully")
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                withAnimation(.easeOut) {
                    isPresented = false
                }
            }
        } catch {
            notificationManager.showError(
                "Failed to update profile. Please try again."
            )
        }
    }
}

#Preview {
    @Previewable @State var shown = true
    return UserRegistrationForm(isPresented: $shown)
        .modelContainer(for: User.self, inMemory: true)
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
}
