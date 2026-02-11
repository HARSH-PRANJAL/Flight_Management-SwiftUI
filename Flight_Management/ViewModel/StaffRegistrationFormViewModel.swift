import PhotosUI
import SwiftUI

@Observable
final class StaffRegistrationFormViewModel {
    var name: String = ""
    var email: String = ""
    var gender: Gender?
    var role: StaffRole?
    var day: String = ""
    var month: String = ""
    var year: String = ""
    var selectedPhoto: PhotosPickerItem?
    var photoData: Data?
    var profilePreview: Image?
    var dob: Date?

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    let years: [String]

    init() {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array(
            (currentYear - 66)...(currentYear - 16)
        ).reversed().map { "\($0)" }
    }

    var daysInMonth: [String] {
        let numberOfDays = Month.numberOfDays(inMonth: month)
        return Array(1...numberOfDays).map(\.description)
    }

    var dateOfBirthComponents: DateComponents {
        var component = DateComponents()
        component.day = Int(day)
        component.month = Int(month)
        component.year = Int(year)
        return component
    }

    func resetForm() {
        name = ""
        role = nil
        email = ""
        gender = nil
        day = ""
        month = ""
        year = ""
        photoData = nil
        profilePreview = nil
        dob = nil
        fieldErrors = [:]
    }

    func processPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self)
            else { return }
            handleImageData(data)
        } catch {
            print("Photo loading failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func handleImageData(_ data: Data) {
        if let image = UIImage(data: data),
            let compressed = image.jpegData(compressionQuality: 0.78)
        {
            photoData = compressed
            profilePreview = Image(uiImage: UIImage(data: compressed) ?? image)
        } else {
            photoData = data
            if let uiImage = UIImage(data: data) {
                profilePreview = Image(uiImage: uiImage)
            }
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
            fieldErrors[.name] = "Provide correct name. eg. John23 Doe"
            return false
        }

        name = trimmedName
        return true
    }

    func validateEmail() -> Bool {
        let pattern = /^[A-Z0-9a-z._%+-]{1,64}@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/
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
        if day.isEmpty || month.isEmpty || year.isEmpty {
            fieldErrors[.dateOfBirth] = "Date of birth is required"
            return false
        }

        guard let birthDate = Calendar.current.date(from: dateOfBirthComponents)
        else {
            fieldErrors[.dateOfBirth] = "Date of birth is required"
            return false
        }

        let calendar = Calendar.current
        let today = Date()
        guard
            let age = calendar.dateComponents(
                [.year],
                from: birthDate,
                to: today
            ).year
        else {
            fieldErrors[.dateOfBirth] = "Invalid date of birth"
            return false
        }

        let maxAge = getMaxAgeForRole(role)
        if age > maxAge {
            fieldErrors[.dateOfBirth] =
                "Maximum age for \(getAgeRoleDescription(role)) is \(maxAge) years"
            return false
        }

        dob = birthDate
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

    private func getMaxAgeForRole(_ role: StaffRole?) -> Int {
        switch role {
        case .pilot, .coPilot:
            return 65
        case .cabinCrew:
            return 60
        case .none:
            return Int.max
        }
    }

    private func getAgeRoleDescription(_ role: StaffRole?) -> String {
        switch role {
        case .pilot, .coPilot:
            return "pilots"
        case .cabinCrew:
            return "cabin crew"
        case .none:
            return "staff"
        }
    }
}
