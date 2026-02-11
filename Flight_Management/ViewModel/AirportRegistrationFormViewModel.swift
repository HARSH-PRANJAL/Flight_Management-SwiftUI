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
        let trimmed = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            fieldErrors[.code] = "Code cannot be empty."
            return false
        }
        
        if trimmed.count != 3 {
            fieldErrors[.code] = "Code must be 3 characters (e.g., JFK, LHR)."
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

    func saveAirport(to context: ModelContext) -> Bool {
        guard validateAll() else { return false }
        
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
}

