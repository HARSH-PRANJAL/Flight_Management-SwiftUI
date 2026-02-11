import SwiftUI
import SwiftData

@Observable
final class AircraftRegistrationFormViewModel {
    var registrationNumber: String = ""
    var type: String = ""
    var seatingCapacity: String = ""
    var minimumStaffRequired: [StaffRole: String] = [:]

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    init() {
        for role in StaffRole.allCases {
            minimumStaffRequired[role] = "0"
        }
    }

    func resetForm() {
        registrationNumber = ""
        type = ""
        seatingCapacity = ""
        fieldErrors = [:]
        for role in StaffRole.allCases {
            minimumStaffRequired[role] = ""
        }
    }
}

// MARK: - Validators
extension AircraftRegistrationFormViewModel {
    func validateRegistrationNumber() -> Bool {
        let trimmed = registrationNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            fieldErrors[.registrationNumber] = "Registration number cannot be empty."
            return false
        }
        
        if trimmed.count < 3 {
            fieldErrors[.registrationNumber] = "Registration number must be at least 3 characters."
            return false
        }
        
        registrationNumber = trimmed
        return true
    }

    func validateType() -> Bool {
        let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            fieldErrors[.type] = "Aircraft type cannot be empty."
            return false
        }
        
        type = trimmed
        return true
    }

    func validateSeatingCapacity() -> Bool {
        guard let capacity = Int(seatingCapacity), capacity > 0 else {
            fieldErrors[.seatingCapacity] = "Enter a valid seating capacity."
            return false
        }
        
        return true
    }

    func validateMinimumStaffRequired() -> Bool {
        for role in StaffRole.allCases {
            if let count = Int(minimumStaffRequired[role] ?? ""), count < 0 {
                fieldErrors[.minimumStaffRequired] = "Staff count cannot be negative."
                return false
            }
        }
        return true
    }

    func validateAll() -> Bool {
        var isValid = true
        
        isValid = validateRegistrationNumber() && isValid
        isValid = validateType() && isValid
        isValid = validateSeatingCapacity() && isValid
        isValid = validateMinimumStaffRequired() && isValid
        
        return isValid
    }

    func saveAircraft(to context: ModelContext) -> Bool {
        guard validateAll() else { return false }
        
        let capacity = Int(seatingCapacity) ?? 0
        var staffDict: [StaffRole: Int] = [:]
        
        for role in StaffRole.allCases {
            if let count = Int(minimumStaffRequired[role] ?? "0") {
                staffDict[role] = max(0, count)
            }
        }
        
        let aircraft = Aircraft(
            registrationNumber: registrationNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type.trimmingCharacters(in: .whitespacesAndNewlines),
            seatingCapacity: capacity,
            minimumStaffRequired: staffDict
        )
        
        context.insert(aircraft)
        
        do {
            try context.save()
            submissionState = .success
            return true
        } catch {
            submissionState = .error
            return false
        }
    }
}
