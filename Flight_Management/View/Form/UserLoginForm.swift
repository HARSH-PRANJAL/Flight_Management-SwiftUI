import SwiftData
import SwiftUI

struct UserLoginForm: View {
    @Environment(\.modelContext) var context
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("currentUserName") private var currentUserName: String = ""
    @AppStorage("currentUserRole") private var currentUserRole: String = ""

    @State private var name: String = ""
    @State private var password: String = ""
    @State private var showRegistration = false
    @State private var errorMessage: String? = nil

    @FocusState private var focusState: FormFocus?

    @Query private var users: [User]

    var body: some View {
        NavigationStack {
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
                                label: "Username",
                                placeholder: "Enter your name",
                                focus: .name,
                                hasError: false,
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

                            FormInputField(
                                label: "Password",
                                placeholder: "Enter your password",
                                focus: .password,
                                hasError: false,
                                text: $password,
                                focusedField: $focusState
                            )
                            .onChange(of: password) { oldValue, newValue in
                                if newValue.count > 255 {
                                    password = String(newValue.prefix(255))
                                }
                            }
                        }
                        .padding()

                        Button(action: handleLogin) {
                            Text("Login")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    name == "" || password == "" ? Color(.systemBlue).opacity(0.7) : Color(.systemBlue)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(name == "" || password == "")
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
                        if !currentUserName.isEmpty {
                            SuccessOverlay(message: "Logged in as \(currentUserName)")
                        }
                    }
                }
            }
        }
    }

    private func handleLogin() {
        errorMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let matched = users.first(where: {
            $0.name == trimmedName && $0.password == password
        }) {
            currentUserName = matched.name
            currentUserRole = matched.role.rawValue
            isLoggedIn = true
        } else {
            errorMessage = "Invalid credentials"
        }
    }
}

#Preview {
    UserLoginForm()
        .modelContainer(for: User.self, inMemory: true)
}
