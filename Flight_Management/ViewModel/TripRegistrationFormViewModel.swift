import Foundation
import SwiftData
import SwiftUI

@Observable
final class TripRegistrationFormViewModel {
    var flightNumber: String = ""
    var scheduledDeparture: Date = Date()
    var selectedRoute: Route?
    var selectedAircraft: Aircraft?
    var selectedStaffIDs: Set<String> = []

    var fieldErrors: [String: String] = [:]
    var submissionState: SubmissionState = .none
    
    var isEditMode: Bool = false
    var tripToEdit: Trip?
    
    init() {}
    
    init(trip: Trip) {
        self.isEditMode = true
        self.tripToEdit = trip
        self.loadTripData(trip)
    }
    
    private func loadTripData(_ trip: Trip) {
        self.flightNumber = trip.flightNumber
        self.scheduledDeparture = trip.scheduledDepartureTime
        self.selectedRoute = trip.route
        self.selectedAircraft = trip.aircraft
        self.selectedStaffIDs = Set(trip.staffs.map { $0.id.uuidString })
    }

    func toggleStaff(_ staff: Staff) {
        let id = staff.id.uuidString
        if selectedStaffIDs.contains(id) {
            selectedStaffIDs.remove(id)
        } else {
            selectedStaffIDs.insert(id)
        }
    }

    func isSelected(_ staff: Staff) -> Bool {
        selectedStaffIDs.contains(staff.id.uuidString)
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
        if selectedStaffIDs.isEmpty {
            fieldErrors["staff"] = "Assign at least one staff"
            valid = false
        }

        if let aircraft = selectedAircraft {
            // map selected staff IDs to roles will be checked by caller (form has access to staff list)
            // here we only ensure counts will be checked in submit
        }

        return valid
    }
}
