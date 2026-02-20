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
    let years: [String]

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none
    
    var isEditMode: Bool = false
    var staffToEdit: Staff?

    struct Snapshot: Equatable {
        let name: String
        let email: String
        let gender: Gender?
        let role: StaffRole?
        let day: String
        let month: String
        let year: String
        let photoData: Data?
        let selectedPhoto: PhotosPickerItem?
        let profilePreview: Image?
        let dob: Date?
    }

    var originalSnapshot: Snapshot?

    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }

    init() {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array(
            (currentYear - 66)...(currentYear - 16)
        ).reversed().map { "\($0)" }
    }
    
    init(staff: Staff) {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array(
            (currentYear - 66)...(currentYear - 16)
        ).reversed().map { "\($0)" }
        
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
            day: day,
            month: month,
            year: year,
            photoData: photoData,
            selectedPhoto: selectedPhoto,
            profilePreview: profilePreview,
            dob: dob,
        )
    }
    
    private func loadStaffData(_ staff: Staff) {
        self.name = staff.name
        self.email = staff.email
        self.gender = staff.gender
        self.role = staff.designation
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: staff.dob)
        self.year = String(components.year ?? 0)
        self.month = String(components.month ?? 0)
        self.day = String(components.day ?? 0)
        self.profilePreview =  staff.avatarImage
        self.dob = staff.dob
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
            fieldErrors[.date] = "Date of birth is required"
            return false
        }

        guard let birthDate = Calendar.current.date(from: dateOfBirthComponents)
        else {
            fieldErrors[.date] = "Date of birth is required"
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
            fieldErrors[.date] = "Invalid date of birth"
            return false
        }

        let maxAge = getMaxAgeForRole(role)
        if age > maxAge {
            fieldErrors[.date] =
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
