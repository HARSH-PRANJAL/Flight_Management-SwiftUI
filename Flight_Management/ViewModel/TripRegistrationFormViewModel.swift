import Foundation
import SwiftData
import SwiftUI

@Observable
final class TripRegistrationFormViewModel {
    var flightNumber: String = ""
    var scheduledDeparture: Date = Date()
    var selectedRoute: Route?
    var selectedAircraft: Aircraft?
    var selectedPilots: [Staff] = []
    var selectedCoPilots: [Staff] = []
    var selectedCrewMembers: [Staff] = []

    var fieldErrors: [String: String] = [:]
    var submissionState: SubmissionState = .none

    var originalSnapshot: Snapshot?
    struct Snapshot: Equatable {
        let flightNumber: String
        let scheduledDeparture: Date
        let selectedRoute: Route?
        let selectedAircraft: Aircraft?
        let selectedPilotIds: Set<UUID>
        let selectedCoPilotIds: Set<UUID>
        let selectedCrewMemberIds: Set<UUID>
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
            selectedPilotIds: Set(selectedPilots.map(\.id)),
            selectedCoPilotIds: Set(selectedCoPilots.map(\.id)),
            selectedCrewMemberIds: Set(selectedCrewMembers.map(\.id))
        )
    }

    func addStaff(_ staff: Staff, role: StaffRole) {
        switch role {
        case .pilot where !selectedPilots.contains(where: { $0.id == staff.id }):
            selectedPilots.append(staff)
        case .coPilot
        where !selectedCoPilots.contains(where: { $0.id == staff.id }):
            selectedCoPilots.append(staff)
        case .cabinCrew
        where !selectedCrewMembers.contains(where: { $0.id == staff.id }):
            selectedCrewMembers.append(staff)
        default:
            break
        }
    }

    func removeStaff(_ staff: Staff, role: StaffRole) {
        switch role {
        case .pilot: selectedPilots.removeAll { $0.id == staff.id }
        case .coPilot: selectedCoPilots.removeAll { $0.id == staff.id }
        case .cabinCrew: selectedCrewMembers.removeAll { $0.id == staff.id }
        }
    }

    var allSelectedStaff: [Staff] {
        selectedPilots + selectedCoPilots + selectedCrewMembers
    }

    func validate(minRequired: [StaffRole: Int]) -> Bool {
        fieldErrors.removeAll()
        var valid = true

        if flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
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
        if scheduledDeparture <= Date() {
            fieldErrors["departureDate"] = "Departure must be in the future"
            valid = false
        }
        let counts: [StaffRole: Int] = [
            .pilot: selectedPilots.count,
            .coPilot: selectedCoPilots.count,
            .cabinCrew: selectedCrewMembers.count,
        ]
        for (role, minReq) in minRequired where minReq > 0 {
            let assigned = counts[role] ?? 0
            if assigned < minReq {
                fieldErrors["staff"] =
                    "Aircraft requires at least \(minReq) \(role.rawValue); \(assigned) assigned"
                valid = false
            }
        }
        return valid
    }
}
