import SwiftUI
import SwiftData

@Model
class Staff {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var trips: [Trip]

    var name: String
    var gender: Gender
    var email: String
    var profileImage: Data?
    var designation: StaffRole
    var dob: Date

    var lastCompletedTrip: Trip? = nil
    var nextScheduledTrip: Trip? = nil
    var currentTrip: Trip? = nil
    var isMarkedUnavailable: Bool = false

    var totalTripHours: Double {
        return trips.filter({
            $0.isCompleted == true || $0.isCancelled == true
        }).reduce(0.0) {
            $0
                + $1.estimatedArrivalTime.timeIntervalSince(
                    $1.scheduledDepartureTime
                )
        } / 3600.0
    }

    var completedTrips: [Trip] {
        return trips.filter({
            $0.isCompleted == true || $0.isCancelled == true
        })
    }

    var scheduledTrips: [Trip] {
        return trips.filter({
            $0.currentStatus == .scheduled
        })
    }

    var currentStatus: StaffAvailabilityStatus {
        if isMarkedUnavailable {
            return .unavailable
        } else {
            if currentTrip != nil {
                return .onDuty
            } else {
                return .available
            }
        }
    }

    var avatarImage: Image? {
        if let data = profileImage,
            let uiImage = UIImage(data: data)
        {
            return Image(uiImage: uiImage)
        }

        return nil
    }

    init(
        name: String,
        designation: StaffRole,
        gender: Gender,
        email: String,
        profileImage: Data? = nil,
        dob: Date
    ) {
        self.id = UUID()
        self.name = name
        self.designation = designation
        self.gender = gender
        self.email = email
        self.profileImage = profileImage
        self.trips = []
        self.dob = dob
    }

    func isAvailable(from: Date, to: Date) -> Bool {
        return !scheduledTrips.contains(where: {
            $0.estimatedArrivalTime > from && $0.scheduledDepartureTime < to
        })
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

    func markUnavailable() {
        for trip in self.scheduledTrips {
            trip.cancel()
        }

        let tripInserted =
            self.trips.filter {
                $0.id == self.currentTrip?.id
            }.count == 0

        if tripInserted && currentTrip != nil {
            self.trips.append(self.currentTrip!)
        }

        if currentTrip != nil {
            self.lastCompletedTrip = self.currentTrip
        }
        self.currentTrip = nil
        self.isMarkedUnavailable = true
    }
}
