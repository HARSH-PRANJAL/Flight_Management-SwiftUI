import SwiftData
import Foundation

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

    var completedTrips: [Trip] {
        return trips.filter({
            $0.isCompleted == true
        })
    }

    var totaltripHours: Double {
        return trips.filter({
            $0.isCompleted == true || $0.isCancelled == true
        }).reduce(0.0) {
            $0
                + $1.estimatedArrivalTime.timeIntervalSince(
                    $1.scheduledDepartureTime
                )
        }
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
    }

    func updateLastAndNextScheduledTrip(completedTrip: Trip) {
        lastCompletedTrip = completedTrip
        currentTrip = nil
        updateNextScheduledTrip(after: completedTrip)
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

    func isAvailable(from: Date, to: Date, availableStaff: [StaffRole: Int])
        -> Bool
    {
        for (role, number) in availableStaff {
            if minimumStaffRequired[role, default: 0] > number {
                return false
            }
        }

        return !scheduledTrips.contains(where: {
            $0.estimatedArrivalTime > from && $0.scheduledDepartureTime < to
        })
    }

}
