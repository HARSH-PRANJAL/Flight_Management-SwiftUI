// Flight_Management/ViewModel/AirportRegistrationFormViewModel.swift

import SwiftUI
import SwiftData

@Observable
final class AirportRegistrationFormViewModel {
    var code: String = ""
    var name: String = ""
    var city: String = ""
    var country: String = ""

    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var isEditMode: Bool = false
    var airportToEdit: Airport?

    var originalSnapshot: Snapshot?
    struct Snapshot: Equatable {
        let code: String
        let name: String
        let city: String
        let country: String
    }

    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }

    func currentSnapshot() -> Snapshot {
        Snapshot(code: code, name: name, city: city, country: country)
    }

    init() {}

    init(airport: Airport) {
        self.isEditMode = true
        self.airportToEdit = airport
        self.code = airport.code
        self.name = airport.name
        self.city = airport.city
        self.country = airport.country
    }

    func resetForm() {
        code = ""
        name = ""
        city = ""
        country = ""
        fieldErrors = [:]
    }
}

// MARK: - Validators
extension AirportRegistrationFormViewModel {
    func validateCode() -> Bool {
        let trimmed = code.uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            fieldErrors[.code] = "Code cannot be empty."
            return false
        }
        if trimmed.count < 3 {
            fieldErrors[.code] = "Code should be at least 3 characters."
            return false
        }

        code = trimmed
        return true
    }

    func validateName() -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            fieldErrors[.name] = "Airport name cannot be empty."
            return false
        }

        name = trimmed
        return true
    }

    func validateCity() -> Bool {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            fieldErrors[.city] = "City cannot be empty."
            return false
        }

        city = trimmed
        return true
    }

    func validateCountry() -> Bool {
        let trimmed = country.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            fieldErrors[.country] = "Country cannot be empty."
            return false
        }

        country = trimmed
        return true
    }

    func validateAll() -> Bool {
        var isValid = true
        isValid = validateCode() && isValid
        isValid = validateName() && isValid
        isValid = validateCity() && isValid
        isValid = validateCountry() && isValid
        return isValid
    }
}

// MARK: - Util
extension AirportRegistrationFormViewModel {
    func saveAirport(to context: ModelContext) -> Bool {
        let airport = Airport(
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        context.insert(airport)

        do {
            try context.save()
            submissionState = .success
            return true
        } catch {
            submissionState = .error
            return false
        }
    }

    func updateAirport(_ airport: Airport, in context: ModelContext) -> Bool {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)

        airport.code = trimmedCode
        airport.name = trimmedName
        airport.city = trimmedCity
        airport.country = trimmedCountry
        airport.searchKey = "\(trimmedName) \(trimmedCode) \(trimmedCity) \(trimmedCountry)"
            .lowercased()

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
