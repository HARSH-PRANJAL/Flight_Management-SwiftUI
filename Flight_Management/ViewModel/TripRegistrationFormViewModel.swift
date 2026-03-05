import Foundation
import SwiftData
import SwiftUI

@Observable
final class TripRegistrationFormViewModel {
    var tripNumber: String = ""
    var scheduledDeparture: Date = Date()
    var selectedRoute: Route?
    var selectedAircraft: Aircraft?

    var selectedPilots: [Staff] = []
    var selectedCoPilots: [Staff] = []
    var selectedCrewMembers: [Staff] = []

    var availableStaffs: [Staff] = []
    var availableStaffCountsByRole: [StaffRole: Int] = [:]
    var availableAircraft: [Aircraft] = []

    var hasAvailableAircraft: Bool = false
    var fieldErrors: [FieldError: String] = [:]
    var submissionState: SubmissionState = .none

    var originalSnapshot: Snapshot?

    struct Snapshot: Equatable {
        let flightNumber: String
        let scheduledDeparture: Date
        let selectedRouteId: UUID?
        let selectedAircraftId: UUID?
        let selectedPilotIds: Set<UUID>
        let selectedCoPilotIds: Set<UUID>
        let selectedCrewMemberIds: Set<UUID>
    }

    var isDirty: Bool {
        guard let original = originalSnapshot else { return false }
        return currentSnapshot() != original
    }

    var isEditMode: Bool = false
    var tripToEdit: Trip?

    init() {}

    init(trip: Trip) {
        self.isEditMode = true
        self.tripToEdit = trip
        self.tripNumber = trip.tripNumber
        self.scheduledDeparture = trip.scheduledDepartureTime
        self.selectedRoute = trip.route
        self.selectedAircraft = trip.aircraft
        self.selectedPilots = trip.staffs.filter { $0.designation == .pilot }
        self.selectedCoPilots = trip.staffs.filter { $0.designation == .coPilot }
        self.selectedCrewMembers = trip.staffs.filter { $0.designation == .cabinCrew }
    }

    func currentSnapshot() -> Snapshot {
        Snapshot(
            flightNumber: tripNumber,
            scheduledDeparture: scheduledDeparture,
            selectedRouteId: selectedRoute?.id,
            selectedAircraftId: selectedAircraft?.id,
            selectedPilotIds: Set(selectedPilots.map(\.id)),
            selectedCoPilotIds: Set(selectedCoPilots.map(\.id)),
            selectedCrewMemberIds: Set(selectedCrewMembers.map(\.id))
        )
    }

    func addStaff(_ staff: Staff, role: StaffRole) {
        switch role {
        case .pilot where !selectedPilots.contains(where: { $0.id == staff.id }):
            selectedPilots.append(staff)

        case .coPilot where !selectedCoPilots.contains(where: { $0.id == staff.id }):
            selectedCoPilots.append(staff)

        case .cabinCrew where !selectedCrewMembers.contains(where: { $0.id == staff.id }):
            selectedCrewMembers.append(staff)

        default:
            break
        }
    }

    func removeStaff(_ staff: Staff, role: StaffRole) {
        switch role {
        case .pilot:
            selectedPilots.removeAll { $0.id == staff.id }
        case .coPilot:
            selectedCoPilots.removeAll { $0.id == staff.id }
        case .cabinCrew:
            selectedCrewMembers.removeAll { $0.id == staff.id }
        }
    }

    var allSelectedStaff: [Staff] {
        selectedPilots + selectedCoPilots + selectedCrewMembers
    }

    func validate(minRequired: [StaffRole: Int]) -> Bool {
        fieldErrors.removeAll()
        var valid = true

        let trimmed = tripNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            fieldErrors[.tripNumber] = "Trip number is required."
            valid = false
        } else if trimmed.count > 50 {
            fieldErrors[.tripNumber] = "Trip number cannot exceed 50 characters."
            valid = false
        } else {
            let allowed =
                CharacterSet.letters
                .union(.decimalDigits)
                .union(CharacterSet(charactersIn: "-"))

            if !trimmed.unicodeScalars.allSatisfy(allowed.contains) {
                fieldErrors[.tripNumber] = "Only letters, numbers and '-' allowed."
                valid = false
            }
        }

        if valid { tripNumber = trimmed }

        if selectedRoute == nil {
            fieldErrors[.route] = "Route is required."
            valid = false
        }

        if selectedAircraft == nil {
            fieldErrors[.aircraft] = "Aircraft is required."
            valid = false
        }

        if scheduledDeparture <= Date() {
            fieldErrors[.date] = "Departure must be in the future."
            valid = false
        }

        let assignedCounts: [StaffRole: Int] = [
            .pilot: selectedPilots.count,
            .coPilot: selectedCoPilots.count,
            .cabinCrew: selectedCrewMembers.count,
        ]

        for (role, minReq) in minRequired where minReq > 0 {
            if (assignedCounts[role] ?? 0) < minReq {
                fieldErrors[.staff] =
                    "Aircraft requires at least \(minReq) \(role.rawValue)."
                valid = false
            }
        }

        return valid
    }
}

extension TripRegistrationFormViewModel {

    func recomputeAvailability(
        staffs: [Staff],
        aircrafts: [Aircraft]
    ) {
        guard let route = selectedRoute else {
            availableStaffs = []
            availableStaffCountsByRole = [:]
            hasAvailableAircraft = false
            return
        }

        let endDate = scheduledDeparture.addingTimeInterval(
            TimeInterval(route.totalPlannedDurationMinutes * 60)
        )

        let filteredStaff = staffs.filter {
            $0.isAvailable(from: scheduledDeparture, to: endDate)
        }

        availableStaffs = filteredStaff

        var counts: [StaffRole: Int] = [
            .pilot: 0,
            .coPilot: 0,
            .cabinCrew: 0,
        ]

        for staff in filteredStaff {
            counts[staff.designation, default: 0] += 1
        }

        availableStaffCountsByRole = counts

        availableAircraft = aircrafts.filter {
            $0.isAvailable(
                from: scheduledDeparture,
                to: endDate,
                availableStaff: counts
            )
        }

        hasAvailableAircraft = !availableAircraft.isEmpty
    }
}
