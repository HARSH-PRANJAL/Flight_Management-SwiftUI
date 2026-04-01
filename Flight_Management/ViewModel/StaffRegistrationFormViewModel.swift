import PhotosUI
import SwiftUI
import UIKit

@Observable
final class StaffRegistrationFormViewModel {
    var name: String = ""
    var email: String = ""
    var gender: Gender?
    var role: StaffRole?
    var selectedPhoto: PhotosPickerItem?
    var photoData: Data?
    var profilePreview: Image?
    var profileBgColor: ColorData = ColorData(Color.gray)
    var dob: Date = Date()
    var years: [String] = []

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var isEditMode: Bool = false
    var staffToEdit: Staff?

    struct Snapshot: Equatable {
        let name: String
        let email: String
        let gender: Gender?
        let role: StaffRole?
        let photoData: Data?
        let selectedPhoto: PhotosPickerItem?
        let profilePreview: Image?
        let dob: Date
    }

    var originalSnapshot: Snapshot?

    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }

    init() {}

    init(staff: Staff) {
        self.isEditMode = true
        self.staffToEdit = staff
        self.loadStaffData(staff)
    }

    func currentSnapshot() -> Snapshot {
        return Snapshot(
            name: name,
            email: email,
            gender: gender,
            role: role,
            photoData: photoData,
            selectedPhoto: selectedPhoto,
            profilePreview: profilePreview,
            dob: dob
        )
    }

    private func loadStaffData(_ staff: Staff) {
        self.name = staff.name
        self.email = staff.email
        self.gender = staff.gender
        self.role = staff.designation
        self.profilePreview = staff.avatarImage
        self.profileBgColor = staff.profileBgColor
        self.dob = staff.dob
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
                print(
                    "✅ [StaffRegistrationFormViewModel] profileBgColor set: R=\(profileBgColor.red) G=\(profileBgColor.green) B=\(profileBgColor.blue)"
                )
            } else {
                profileBgColor = ColorData(Color.gray)
                print(
                    "⚠️ [StaffRegistrationFormViewModel] Using default gray - extraction failed or no image"
                )
            }
        } catch {
            print("Photo loading failed: \(error.localizedDescription)")
        }
    }
}

// MARK: Validators
extension StaffRegistrationFormViewModel {
    func validateName() -> Bool {
        let pattern = /^[A-Za-z][A-Za-z0-9 ]+$/
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            fieldErrors[.name] = "Name cannot be empty."
            return false
        }

        guard trimmedName.wholeMatch(of: pattern) != nil else {
            fieldErrors[.name] = "Provide correct name. eg. John Doe"
            return false
        }

        name = trimmedName
        return true
    }

    func validateEmail() -> Bool {
        let pattern = /^[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$/
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            fieldErrors[.email] = "Email cannot be empty."
            return false
        }

        guard email.wholeMatch(of: pattern) != nil else {
            fieldErrors[.email] = "Provide correct email."
            return false
        }

        guard email.count <= 254 else {
            fieldErrors[.email] =
                "Email cannot be more than 254 characters long."
            return false
        }

        return true
    }

    func validateDateOfBirth() -> Bool {
        if Calendar.current.isDateInToday(dob) {
            fieldErrors[.date] = "Date of birth can not be empty."
            return false
        }

        let calendar = Calendar.current
        let today = Date()

        guard
            let age = calendar.dateComponents(
                [.year],
                from: dob,
                to: today
            ).year
        else {
            fieldErrors[.date] = "Invalid date of birth"
            return false
        }

        if age < 16 {
            fieldErrors[.date] = "Staff must be at least 16 years old"
            return false
        }

        let maxAge = getMaxAgeForRole(role)
        if age > maxAge {
            fieldErrors[.date] =
                "Maximum age for \(role?.rawValue ?? "staff") is \(maxAge) years"
            return false
        }

        return true
    }

    func validateGender() -> Bool {
        guard gender != nil else {
            fieldErrors[.gender] = "Please select a gender."
            return false
        }
        return true
    }

    func validateDesignation() -> Bool {
        guard role != nil else {
            fieldErrors[.role] = "Please select a staff designation."
            return false
        }
        return true
    }

    var minBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -16, to: Date())
            ?? Date.distantPast
    }

    var maxBirthDate: Date {
        if role == nil {
            return Calendar.current.date(
                byAdding: .year,
                value: -70,
                to: Date()
            )
                ?? Date.distantPast
        }
        let maxAge = getMaxAgeForRole(role)
        return Calendar.current.date(
            byAdding: .year,
            value: -maxAge,
            to: Date()
        )
            ?? Date.distantPast
    }

    private func getMaxAgeForRole(_ role: StaffRole?) -> Int {
        switch role {
        case .pilot, .coPilot:
            return 65
        case .cabinCrew:
            return 60
        default:
            return 120
        }
    }
}
