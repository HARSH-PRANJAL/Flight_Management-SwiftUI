import SwiftData
import SwiftUI

@Observable
final class AircraftRegistrationFormViewModel {
    var registrationNumber: String = ""
    var type: String = ""
    var seatingCapacity: String = ""
    var minimumStaffRequired: [StaffRole: String] = [:]
    var isEditing: Bool = false

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var originalSnapshot: Snapshot?
    struct Snapshot: Equatable {
        let registrationNumber: String
        let type: String
        let seatingCapacity: String
        let minimumStaffRequired: [StaffRole: String]
    }

    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }

    func currentSnapshot() -> Snapshot {
        return Snapshot(
            registrationNumber: registrationNumber,
            type: type,
            seatingCapacity: seatingCapacity,
            minimumStaffRequired: minimumStaffRequired
        )
    }

    init() {
        for role in StaffRole.allCases {
            minimumStaffRequired[role] = ""
        }
    }

    init(aircraft: Aircraft) {
        self.registrationNumber = aircraft.registrationNumber
        self.type = aircraft.type
        self.seatingCapacity = String(aircraft.seatingCapacity)

        for role in StaffRole.allCases {
            self.minimumStaffRequired[role] = String(
                aircraft.minimumStaffRequired[role] ?? 0
            )
        }
        self.isEditing = true
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
        let trimmed = registrationNumber.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed.isEmpty {
            fieldErrors[.name] =
                "Registration number cannot be empty."
            return false
        }

        if trimmed.count < 3 {
            fieldErrors[.name] =
                "Registration number must be at least 3 characters."
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
            fieldErrors[.seatingCapacity] = "Enter seating capacity."
            return false
        }
        if capacity > 500 {
            fieldErrors[.seatingCapacity] =
                "Number of seats cannot be more than 500."
            return false
        }
        return true
    }

    func validateMinimumStaffRequired() -> Bool {
        let totalCount: Int = minimumStaffRequired.reduce(0) {
            $0 + (Int($1.value) ?? 0)
        }

        let pilotCount = Int(minimumStaffRequired[.pilot] ?? "0") ?? 0
        let copilotCount = Int(minimumStaffRequired[.coPilot] ?? "0") ?? 0
        let crewCount = Int(minimumStaffRequired[.cabinCrew] ?? "0") ?? 0

        if pilotCount == 0 && copilotCount == 0 {
            fieldErrors[.pilot] =
                "At least one pilot or co-pilot must be required."
            return false
        }
        if totalCount == 0 {
            fieldErrors[.pilot] =
                "Provide operational staff count."
            fieldErrors[.copilot] = ""
            fieldErrors[.crew] = ""
            return false
        }
        if pilotCount > 5 {
            fieldErrors[.pilot] =
                "Number of pilots cannot be more than 5."
            return false
        }
        if pilotCount + copilotCount > 5 {
            let allowedCopilots = max(0, 5 - pilotCount)
            fieldErrors[.copilot] =
                "Maximum allowed number of copilots is \(allowedCopilots)."
            return false
        }
        if crewCount > 12 {
            fieldErrors[.crew] =
                "Number of crew members cannot be more than 12."
            return false
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
        let capacity = Int(seatingCapacity) ?? 0
        var staffDict: [StaffRole: Int] = [:]

        for role in StaffRole.allCases {
            if let count = Int(minimumStaffRequired[role] ?? "0") {
                staffDict[role] = max(0, count)
            }
        }

        let aircraft = Aircraft(
            registrationNumber: registrationNumber.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
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

    func updateAircraft(_ aircraft: Aircraft, in context: ModelContext) -> Bool
    {
        let trimmedRegistration =
            registrationNumber.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        aircraft.registrationNumber = trimmedRegistration
        aircraft.registrationNumberSearchKey = Aircraft.normalisedSearchKey(
            from: trimmedRegistration
        )
        aircraft.type = type.trimmingCharacters(in: .whitespacesAndNewlines)
        aircraft.seatingCapacity = Int(seatingCapacity) ?? 0

        var staffDict: [StaffRole: Int] = [:]
        for role in StaffRole.allCases {
            if let count = Int(minimumStaffRequired[role] ?? "0") {
                staffDict[role] = max(0, count)
            }
        }
        aircraft.minimumStaffRequired = staffDict

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
