import SwiftData
import SwiftUI

@Model
class Staff {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var trips: [Trip]

    var name: String
    var nameSearchKey: String
    var gender: Gender
    var email: String
    var profileImage: Data?
    var profileBgColor: ColorData
    var designation: StaffRole
    var dob: Date

    var lastCompletedTrip: Trip? = nil
    var nextScheduledTrip: Trip? = nil
    var currentTrip: Trip? = nil
    var isMarkedUnavailable: Bool = false
    var totalTripHours: Double

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
        profileBgColor: ColorData = ColorData(Color.gray),
        dob: Date
    ) {
        self.id = UUID()
        self.name = name
        self.nameSearchKey = Staff.normalisedSearchKey(from: name)
        self.designation = designation
        self.gender = gender
        self.email = email
        self.profileImage = profileImage
        self.profileBgColor = profileBgColor
        self.trips = []
        self.dob = dob
        self.totalTripHours = 0
    }
    
    func addTripHours(for trip: Trip) {
        let hours =
            trip.estimatedArrivalTime
            .timeIntervalSince(trip.scheduledDepartureTime) / 3600.0

        totalTripHours += max(hours, 0)
    }

    // True if the staff has no overlapping trip (scheduled or in progress) in the window.
    func isAvailable(from: Date, to: Date) -> Bool {

        if isMarkedUnavailable {
            return false
        }
        
        return !trips.contains(where: { trip in

            guard !trip.isCancelled && !trip.isCompleted else { return false }

            let departure = trip.scheduledDepartureTime
            let arrival = trip.estimatedArrivalTime

            return departure < to && arrival > from
        })
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

    func markUnavailable() {
        for trip in self.scheduledTrips {
            trip.cancel()
        }

        if currentTrip != nil {
            self.lastCompletedTrip = self.currentTrip!
        }
        self.currentTrip = nil
        self.isMarkedUnavailable = true
    }
}

extension Staff {
    static func normalisedSearchKey(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        let withoutWhitespace =
            trimmed
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        return withoutWhitespace.lowercased()
    }
}
