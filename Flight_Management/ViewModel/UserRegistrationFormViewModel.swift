import PhotosUI
import SwiftData
import SwiftUI

@Observable
final class UserRegistrationFormViewModel {
    var name: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var selectedRole: UserRole? = nil

    var selectedPhoto: PhotosPickerItem?
    var photoData: Data?
    var profilePreview: Image?

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var isEditMode: Bool = false
    var userToEdit: User?

    init() {}

    func loadUserData(_ user: User) async {
        self.name = user.name
        self.email = user.email
        self.selectedRole = user.role

        if let imageData = user.profileImage,
            let uiImage = UIImage(data: imageData)
        {
            self.profilePreview = Image(uiImage: uiImage)
        }
    }

    func resetForm() {
        name = ""
        email = ""
        password = ""
        confirmPassword = ""
        selectedRole = nil
        photoData = nil
        profilePreview = nil
        fieldErrors = [:]
    }

    func processPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self)
            else { return }
            profilePreview = handleImageData(data, photo: &(photoData))
        } catch {
            print("Photo loading failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Validators
extension UserRegistrationFormViewModel {
    func validateName() -> Bool {
        let result = FormValidators.validateName(name)
        if !result.isValid {
            fieldErrors[.name] = result.error
            return false
        }
        fieldErrors.removeValue(forKey: .name)
        return true
    }

    func validateEmail() -> Bool {
        let result = FormValidators.validateEmail(email)
        if !result.isValid {
            fieldErrors[.email] = result.error
            return false
        }
        fieldErrors.removeValue(forKey: .email)
        return true
    }

    func checkEmailUniqueness(context: ModelContext) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let editingID = userToEdit?.id

        do {
            let predicate = #Predicate<User> { user in
                user.email == trimmedEmail
                    && (editingID == nil || user.id != editingID!)
            }

            let descriptor = FetchDescriptor<User>(predicate: predicate)
            let results = try context.fetch(descriptor)

            if !results.isEmpty {
                fieldErrors[.email] = "This email is already registered."
                return false
            }

            fieldErrors.removeValue(forKey: .email)
            return true

        } catch {
            fieldErrors[.email] = "Error checking email uniqueness."
            return false
        }
    }

    func validatePassword() -> Bool {
        // For edit mode, password is optional
        if isEditMode && password.isEmpty {
            fieldErrors.removeValue(forKey: .password)
            return true
        }

        let result = FormValidators.validatePassword(password)
        if !result.isValid {
            fieldErrors[.password] = result.error
            return false
        }
        fieldErrors.removeValue(forKey: .password)
        return true
    }

    func validateConfirmPassword() -> Bool {
        // For edit mode, password is optional
        if isEditMode && password.isEmpty && confirmPassword.isEmpty {
            fieldErrors.removeValue(forKey: .confirmPassword)
            return true
        }

        let result = FormValidators.validatePasswordMatch(
            password,
            confirmPassword
        )
        if !result.isValid {
            fieldErrors[.confirmPassword] = result.error
            return false
        }
        fieldErrors.removeValue(forKey: .confirmPassword)
        return true
    }

    func validateRole() -> Bool {
        guard selectedRole != nil else {
            fieldErrors[.role] = "Please select a role."
            return false
        }
        fieldErrors.removeValue(forKey: .role)
        return true
    }

    func validateAll() -> Bool {
        var isValid = true
        isValid = validateName() && isValid
        isValid = validateEmail() && isValid
        isValid = validatePassword() && isValid
        isValid = validateConfirmPassword() && isValid
        isValid = validateRole() && isValid
        return isValid
    }
}
