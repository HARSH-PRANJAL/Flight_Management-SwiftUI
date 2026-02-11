import Foundation
import SwiftData
import SwiftUI

@Model
class Trip {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .nullify, inverse: \Staff.trips)
    var staffs: [Staff]
    @Relationship(deleteRule: .nullify, inverse: \Aircraft.trips)
    var aircraft: Aircraft
    @Relationship(deleteRule: .cascade)
    var nodeStatuses: [TripNodeStatus]

    var route: Route
    var scheduledDepartureTime: Date
    var flightNumber: String
    var isCancelled: Bool = false
    var isCompleted: Bool = false
    var currentAirportSequence: Int = 1  // sequence of the trip node to visit

    var currentStatus: TripStatus {
        if nodeStatuses.isEmpty {
            return .scheduled
        } else if totalDelayedMinutes > 0 {
            return .delayed
        } else if isCancelled {
            return .cancelled
        } else if isCompleted {
            return .completed
        }

        return .onTime
    }

    // delay for the entire trip completed so far
    var totalDelayedMinutes: Int {
        if nodeStatuses.isEmpty {
            return 0
        } else {
            return nodeStatuses.last!.totalDelayMinutes(
                tripStartTime: scheduledDepartureTime
            )
        }
    }

    // estimated arrival time (cancellation and delay were considered)
    var estimatedArrivalTime: Date {
        let arrivalTime = scheduledDepartureTime.addingTimeInterval(
            TimeInterval(
                route.totalPlannedDurationMinutes * 60
            )
        )

        if isCancelled && nodeStatuses.isEmpty {
            // if trip is cancelled before even starting
            return scheduledDepartureTime
        } else if nodeStatuses.isEmpty {
            // if trip is not started yet
            return arrivalTime
        } else if isCancelled {
            // if flight is cancelled midway between airport A and B
            if nodeStatuses.last!.actualArrivalTime == nil {
                return nodeStatuses[nodeStatuses.count - 1].actualDepartureTime!
            } else {
                // if flight is cancelled after landing on airport B
                return nodeStatuses.last!.actualArrivalTime!
            }
        }

        // trip is ongoing and is delayed (delay can be of 0 mins)
        return arrivalTime.addingTimeInterval(
            TimeInterval(
                totalDelayedMinutes * 60
            )
        )
    }

    // route node for the current airport
    var plannedRouteNode: RouteNode {
        // 0 based indexing
        return route.nodes[currentAirportSequence - 1]
    }

    init(
        staff: [Staff],
        aircraft: Aircraft,
        nodeStatuses: [TripNodeStatus],
        route: Route,
        scheduledDepartureTime: Date,
        flightNumber: String,
        isCancelled: Bool
    ) {
        self.id = UUID()
        self.staffs = staff
        self.aircraft = aircraft
        self.nodeStatuses = []
        self.route = route
        self.scheduledDepartureTime = scheduledDepartureTime
        self.flightNumber = flightNumber
    }

}

// MARK: Trip Scheduling
extension Trip {
    // append the next trip node in nodes
    func scheduleNextAirport() {
        currentAirportSequence += 1
        nodeStatuses.append(
            TripNodeStatus(
                routeNode: self.plannedRouteNode,
            )
        )
    }

    func scheduleCurrentAirportArrival(arrivalTime: Date) {
        if isCancelled {
            return
        }
        
        // can not arrive on source trip node
        if !nodeStatuses.isEmpty {
            nodeStatuses.last!.actualArrivalTime = arrivalTime

            // trip is completed and aircraft is arrived at the last airport of route
            if currentAirportSequence == route.nodes.count {
                aircraft.updateLastAndNextScheduledTrip(completedTrip: self)
                for staff in staffs {
                    staff.updateLastAndNextScheduledTrip(completedTrip: self)
                }
                isCompleted = true
            }
        }
    }

    func scheduleCurrentAirportDeparture(departureTime: Date) {
        if isCancelled {
            return
        }
        
        if nodeStatuses.isEmpty {
            startTrip(departureTime: departureTime)
        } else {
            // takeoff from airport A and prepare airport B
            if !isCompleted {
                nodeStatuses.last!.actualDepartureTime = departureTime
                // airport B will be pushed as current node
                scheduleNextAirport()
            }
        }
    }

    func startTrip(departureTime: Date) {
        if isCancelled {
            return
        }
        nodeStatuses.removeAll()
        nodeStatuses.append(
            TripNodeStatus(
                routeNode: plannedRouteNode,
                actualDepartureTime: departureTime
            )
        )

        aircraft.currentTrip = self
        for staff in staffs {
            staff.currentTrip = self
        }

        scheduleNextAirport()
    }

}

// MARK: Cancel Trip
extension Trip {
    // cancel trip midway or before starting
    func cancel() {
        if isCancelled || isCompleted {
            return
        }

        isCompleted = false

        let hasStarted = !nodeStatuses.isEmpty

        // this trip is the current trip of aircraft
        if aircraft.currentTrip?.id == self.id {
            aircraft.currentTrip = nil
        }
        
        // if trip has started then this is the last completed trip for the aircraft
        if hasStarted {
            aircraft.lastCompletedTrip = self
        }
        aircraft.updateNextScheduledTrip(after: self)

        for staff in staffs {
            // this trip is the current trip of staff
            if staff.currentTrip?.id == self.id {
                staff.currentTrip = nil
            }

            // if trip has started then this is the last completed trip for the staff
            if hasStarted {
                staff.lastCompletedTrip = self
            }
            staff.updateNextScheduledTrip(after: self)
        }
        
        isCancelled = true
    }
}
@Model
class TripNodeStatus {
    @Attribute(.unique)
    var id: UUID
    var routeNode: RouteNode
    var actualArrivalTime: Date?
    var actualDepartureTime: Date?

    init(
        routeNode: RouteNode,
        actualArrivalTime: Date? = nil,
        actualDepartureTime: Date? = nil
    ) {
        self.id = UUID()
        self.routeNode = routeNode
        self.actualArrivalTime = actualArrivalTime
        self.actualDepartureTime = actualDepartureTime
    }

    // total delay from the source of the trip
    func totalDelayMinutes(tripStartTime: Date) -> Int {
        if actualArrivalTime == nil {
            // trip is started from source
            return Calendar.current.dateComponents(
                [.minute],
                from: actualDepartureTime!,
                to: tripStartTime
            ).minute!
        } else {
            let scheduledArrivalTimeMinutes = tripStartTime.addingTimeInterval(
                TimeInterval(routeNode.plannedArrivalOffsetMinutes)
            )

            return Calendar.current.dateComponents(
                [.minute],
                from: actualArrivalTime!,
                to: scheduledArrivalTimeMinutes
            ).minute!
        }
    }
}

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
            return .available
        } else {
            return .assigned
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
    
    var avatarImage: Image {
        if let data = profileImage,
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        
        return Image(systemName: "person.crop.circle.fill")
            .symbolRenderingMode(.monochrome)
    }

    init(name: String, designation: StaffRole, gender: Gender, email: String, profileImage: Data? = nil, dob: Date) {
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
}
