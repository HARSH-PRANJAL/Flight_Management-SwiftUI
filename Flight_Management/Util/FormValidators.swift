import Foundation

struct FormValidators {
    static func validateEmail(_ email: String) -> (
        isValid: Bool, error: String?
    ) {
        let pattern = /^[A-Z0-9a-z._%+-]{1,64}@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            return (false, "Email cannot be empty.")
        }

        guard trimmedEmail.wholeMatch(of: pattern) != nil else {
            return (false, "Provide a valid email address.")
        }

        guard trimmedEmail.count <= 254 else {
            return (false, "Email cannot be more than 254 characters long.")
        }

        return (true, nil)
    }

    static func validateName(_ name: String) -> (isValid: Bool, error: String?)
    {
        let pattern = /^[A-Za-z][A-Za-z ]+$/
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return (false, "Name cannot be empty.")
        }

        guard trimmedName.wholeMatch(of: pattern) != nil else {
            return (
                false,
                "Name must start with a letter and contain only letters and spaces."
            )
        }

        guard trimmedName.count <= 100 else {
            return (false, "Name cannot be more than 100 characters long.")
        }

        return (true, nil)
    }

    static func validatePassword(_ password: String) -> (
        isValid: Bool, error: String?
    ) {
        if password.isEmpty {
            return (false, "Password cannot be empty.")
        }

        guard password.count >= 6 else {
            return (false, "Password must be at least 6 characters long.")
        }

        guard password.count <= 100 else {
            return (false, "Password cannot be more than 100 characters long.")
        }

        return (true, nil)
    }

    static func validatePasswordMatch(
        _ password: String,
        _ confirmPassword: String
    ) -> (isValid: Bool, error: String?) {
        guard password == confirmPassword else {
            return (false, "Passwords do not match.")
        }

        return (true, nil)
    }

    static func validateRequired(_ value: String, fieldName: String) -> (
        isValid: Bool, error: String?
    ) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (false, "\(fieldName) cannot be empty.")
        }
        return (true, nil)
    }
}
