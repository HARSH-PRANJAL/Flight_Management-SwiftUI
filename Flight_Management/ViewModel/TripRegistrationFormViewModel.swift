import Foundation
import SwiftData
import SwiftUI

@Observable
final class TripRegistrationFormViewModel {
    var flightNumber: String = ""
    var scheduledDeparture: Date = Date()
    var selectedRoute: Route?
    var selectedAircraft: Aircraft?
    var selectedPilot: Staff?
    var selectedCoPilot: Staff?
    var selectedCrewMember: Staff?

    var fieldErrors: [String: String] = [:]
    var submissionState: SubmissionState = .none
    
    init() {}

    func validate() -> Bool {
        fieldErrors.removeAll()
        var valid = true

        if flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors["flightNumber"] = "Flight number is required"
            valid = false
        }
        if selectedRoute == nil {
            fieldErrors["route"] = "Route is required"
            valid = false
        }
        if selectedAircraft == nil {
            fieldErrors["aircraft"] = "Aircraft is required"
            valid = false
        }
        if selectedPilot == nil || selectedCoPilot == nil || selectedCrewMember == nil {
            fieldErrors["staff"] = "Pilot, Co-Pilot, and Crew Member are required"
            valid = false
        }

        if let aircraft = selectedAircraft {
            // map selected staff IDs to roles will be checked by caller (form has access to staff list)
            // here we only ensure counts will be checked in submit
        }

        return valid
    }
}
