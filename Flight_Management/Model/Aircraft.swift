import Foundation
import SwiftData

@Model
class Aircraft {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var trips: [Trip]

    var registrationNumber: String
    var type: String
    var seatingCapacity: Int
    var minimumStaffRequired: [StaffRole: Int]
    var lastCompletedTrip: Trip? = nil
    var nextScheduledTrip: Trip? = nil
    var currentTrip: Trip? = nil
    var totalTripHours: Double

    var totalTripsOperated: Int {
        return trips.filter({
            $0.currentStatus == .completed
        }).count
    }

    var scheduledTrips: [Trip] {
        return trips.filter({
            $0.currentStatus == .scheduled
        })
    }

    var currentStatus: AircraftStatus {
        if currentTrip != nil {
            return .assigned
        } else {
            return .available
        }
    }

    init(
        registrationNumber: String,
        type: String,
        seatingCapacity: Int,
        minimumStaffRequired: [StaffRole: Int]
    ) {
        self.id = UUID()
        self.registrationNumber = registrationNumber
        self.type = type
        self.seatingCapacity = seatingCapacity
        self.minimumStaffRequired = minimumStaffRequired
        self.trips = []
        self.totalTripHours = 0
    }

    func addTripHours(for trip: Trip) {
        let hours =
            trip.estimatedArrivalTime
            .timeIntervalSince(trip.scheduledDepartureTime) / 3600.0

        totalTripHours += max(hours, 0)
    }

    func startTrip(_ trip: Trip) {
        currentTrip = trip
        updateNextScheduledTrip(after: trip)
    }

    func updateLastAndNextScheduledTrip(completedTrip: Trip) {
        lastCompletedTrip = completedTrip
        currentTrip = nil
        updateNextScheduledTrip(after: completedTrip)
        addTripHours(for: completedTrip)
    }

    func updateNextScheduledTrip(after previousTrip: Trip) {
        let referenceTime = previousTrip.estimatedArrivalTime

        nextScheduledTrip =
            trips
            .filter {
                !$0.isCancelled && !$0.isCompleted
                    && $0.scheduledDepartureTime > referenceTime
            }
            .min(by: { $0.scheduledDepartureTime < $1.scheduledDepartureTime })
    }

    // True if the aircraft has no overlapping trip in the window and enough staff (by role) are available.
    func isAvailable(from: Date, to: Date, availableStaff: [StaffRole: Int])
        -> Bool
    {

        for (role, number) in availableStaff {
            if minimumStaffRequired[role, default: 0] > number {
                return false
            }
        }

        return !trips.contains(where: { trip in

            guard !trip.isCancelled && !trip.isCompleted else { return false }

            let departure = trip.scheduledDepartureTime
            let arrival = trip.estimatedArrivalTime

            return departure < to && arrival > from
        })
    }

}
