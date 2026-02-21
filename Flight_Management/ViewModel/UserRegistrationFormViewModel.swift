import PhotosUI
import SwiftData
import SwiftUI
import UIKit

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
    var profileBgColor: ColorData = ColorData(Color.gray)

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var isEditMode: Bool = false
    var userToEdit: User?

    var originalSnapshot: Snapshot?
    struct Snapshot: Equatable {
        let name: String
        let email: String
        let password: String
        let confirmPassword: String
        let selectedRole: UserRole?
        let profilePreview: Image?
        let selectedPhoto: PhotosPickerItem?
        let photoData: Data?
    }

    var isDirty: Bool {
        guard let original = originalSnapshot else { return true }
        return original != currentSnapshot()
    }

    func loadUserData(_ user: User) async {
        self.name = user.name
        self.email = user.email
        self.selectedRole = user.role
        self.profileBgColor = user.profileBgColor

        if let imageData = user.profileImage,
            let uiImage = UIImage(data: imageData)
        {
            self.profilePreview = Image(uiImage: uiImage)
        }
    }

    func processPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self)
            else { return }
            profilePreview = handleImageData(data, photo: &(photoData))
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData),
               let dominantColor = await dominantBackgroundColor(from: uiImage)
            {
                profileBgColor = ColorData(uiColor: dominantColor)
                print("✅ [UserRegistrationFormViewModel] profileBgColor set: R=\(profileBgColor.red) G=\(profileBgColor.green) B=\(profileBgColor.blue)")
            } else {
                profileBgColor = ColorData(Color.gray)
                print("⚠️ [UserRegistrationFormViewModel] Using default gray - extraction failed or no image")
            }
        } catch {
            print("Photo loading failed: \(error.localizedDescription)")
        }
    }

    func currentSnapshot() -> Snapshot {
        return Snapshot(
            name: name,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            selectedRole: selectedRole,
            profilePreview: profilePreview,
            selectedPhoto: selectedPhoto,
            photoData: photoData
        )
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
