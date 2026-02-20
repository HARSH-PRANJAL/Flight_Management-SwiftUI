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
    
    var originalSnapshot: Snapshot?
    struct Snapshot: Equatable {
        let flightNumber: String
        let scheduledDeparture: Date
        let selectedRoute: Route?
        let selectedAircraft: Aircraft?
        let selectedPilot: Staff?
        let selectedCoPilot: Staff?
        let selectedCrewMember: Staff?
    }
    
    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }
    
    func currentSnapshot() -> Snapshot {
        Snapshot(
            flightNumber: flightNumber,
            scheduledDeparture: scheduledDeparture,
            selectedRoute: selectedRoute,
            selectedAircraft: selectedAircraft,
            selectedPilot: selectedPilot,
            selectedCoPilot: selectedCoPilot,
            selectedCrewMember: selectedCrewMember
        )
    }

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

        return valid
    }
}
