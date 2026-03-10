import SwiftData
import SwiftUI

struct UserLoginForm: View {
    @Environment(\.modelContext) var context
    @Environment(SessionManager.self) private var session
    @Environment(NotificationManager.self) var notificationManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegistration = false
    @State private var errorMessage: String? = nil

    @FocusState private var focusState: FormFocus?

    @Query private var users: [User]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Text("User Login")
                        .font(Font.largeTitle)
                        .padding(.top, 32)
                    VStack(alignment: .leading, spacing: 8) {
                        FormInputField(
                            label: "Email",
                            placeholder: "Enter your email",
                            focus: .email,
                            hasError: errorMessage != nil,
                            maxLength: 255,
                            text: $email,
                            focusedField: $focusState
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: email) { _, newValue in
                            errorMessage = nil
                        }
                        FormErrorMessage(error: errorMessage)

                        FormSecureInputField(
                            label: "Password",
                            placeholder: "Enter your password",
                            focus: .password,
                            hasError: errorMessage != nil,
                            text: $password,
                            focusedField: $focusState
                        )
                        .onChange(of: password) { _, newValue in
                            errorMessage = nil
                        }
                    }
                    .padding()

                    Button(action: handleLogin) {
                        Text("Login")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                email == "" || password == ""
                                    ? Color(.systemBlue).opacity(0.7)
                                    : Color(.systemBlue)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(email == "" || password == "")
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    HStack {
                        Text("Don't have an account?")
                            .font(.caption)
                        Button(action: { showRegistration = true }) {
                            Text("Register")
                                .font(.caption)
                                .underline()
                        }
                    }
                    .padding(.bottom, 32)
                }
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .stroke(Color(.systemGray4), lineWidth: 1)
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: 8,
                            x: 0,
                            y: 3
                        )
                }
                .sheet(isPresented: $showRegistration) {
                    UserRegistrationForm(isPresented: $showRegistration)
                }
                .padding()
                Spacer()
            }
            .overlay {
                if errorMessage != nil {
                    ErrorOverlay(message: errorMessage!)
                } else {
                    if session.isLoggedIn {
                        SuccessOverlay(
                            message: "Logged in as \(session.user!.name)"
                        )
                    }
                }
            }
        }
    }

    private func handleLogin() {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let matched = users.first(where: {
            $0.email == trimmedEmail && $0.password == password
        }) {
            session.loginUser(matched)
            notificationManager.showSuccess("Logged in as \(matched.name)")
        } else {
            notificationManager.showError("Invalid email or password")
        }
    }
}

#Preview {
    UserLoginForm()
        .modelContainer(for: User.self, inMemory: true)
        .environment(SessionManager.shared)
}
