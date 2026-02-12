import SwiftData
import SwiftUI

struct UserRegistrationForm: View {
    @Environment(\.modelContext) var context
    @Binding var isPresented: Bool
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("currentUserName") private var currentUserName: String = ""
    @AppStorage("currentUserRole") private var currentUserRole: String = ""

    @State private var name: String = ""
    @State private var password: String = ""
    @State private var selectedRole: UserRole? = nil
    @State private var errorMessage: String? = nil

    @FocusState private var focusState: FormFocus?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 20) {
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

                    FormPickerField<UserRole>(
                        label: "Role",
                        placeholder: "User role",
                        focus: .role,
                        hasError: errorMessage != nil,
                        selection: $selectedRole,
                        focusedField: $focusState
                    )
                }
                .padding()

                Button(action: handleRegister) {
                    Text("Register")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            name == "" || password == ""
                                ? Color(.systemGreen).opacity(0.7)
                                : Color(.systemGreen)
                        )
                        .cornerRadius(12)
                }
                .disabled(name == "" || password == "")
                .padding(.horizontal, 16)
                .padding(.top, 24)

                Spacer()
            }
            .navigationTitle("User registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
            .padding(.top, 32)
            .padding()
        }
    }

    private func handleRegister() {
        errorMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let newUser = User(
            name: trimmedName,
            password: password,
            role: selectedRole!
        )
        context.insert(newUser)

        do {
            try context.save()
            currentUserName = newUser.name
            currentUserRole = newUser.role.rawValue
            isLoggedIn = true
            isPresented = false
        } catch {
            errorMessage = "Unable to save user"
        }
    }
}

#Preview {
    @State var shown = true
    return UserRegistrationForm(isPresented: $shown)
        .modelContainer(for: User.self, inMemory: true)
}
