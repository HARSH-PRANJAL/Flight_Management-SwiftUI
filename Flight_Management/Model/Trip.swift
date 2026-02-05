import Foundation
import SwiftData

@Model
class Trip: Hashable {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .nullify, inverse: \Staff.trips)
    var staff: Set<Staff>
    @Relationship(deleteRule: .nullify, inverse: \Aircraft.trips)
    var aircraft: Aircraft?
    @Relationship(deleteRule: .cascade)
    var nodeStatuses: [TripNodeStatus]

    var route: Route
    var scheduledDepartureTime: Date
    var flightNumber: String
    var isCancelled: Bool = false
    var currentAirportSequence: Int = 1
    var scheduleNextAirport: () -> Void

    var currentStatus: TripStatus {
        if nodeStatuses.isEmpty {
            return .scheduled
        } else if totalDelayedMinutes > 0 {
            return .delayed
        } else if isCancelled {
            return .cancelled
        }

        return .onTime
    }

    var totalDelayedMinutes: Int {
        if nodeStatuses.isEmpty {
            return 0
        } else {
            return nodeStatuses.last!.totalDelayMinutes(
                tripStartTime: scheduledDepartureTime
            )
        }
    }

    var estimatedArrivalTime: Date? {
        let arrivalDate = scheduledDepartureTime.addingTimeInterval(
            TimeInterval(
                route.totalPlannedDurationMinutes * 60
            )
        )

        if nodeStatuses.isEmpty {
            return arrivalDate
        }

        return arrivalDate.addingTimeInterval(
            TimeInterval(
                totalDelayedMinutes * 60
            )
        )
    }

    var currentRouteNode: RouteNode {
        return route.nodes[currentAirportSequence]
    }

    init(
        staff: Set<Staff>,
        aircraft: Aircraft? = nil,
        nodeStatuses: [TripNodeStatus],
        route: Route,
        scheduledDepartureTime: Date,
        flightNumber: String,
        isCancelled: Bool
    ) {
        self.id = UUID()
        self.staff = staff
        self.aircraft = aircraft
        self.nodeStatuses = []
        self.route = route
        self.scheduledDepartureTime = scheduledDepartureTime
        self.flightNumber = flightNumber

        self.scheduleNextAirport = {
            self.currentAirportSequence += 1
            self.nodeStatuses.append(
                TripNodeStatus(
                    routeNode: self.currentRouteNode,
                    sequence: self.currentAirportSequence
                )
            )
        }
    }

    func scheduleCurrentAirportArrival(arrivalTime: Date) {
        if !nodeStatuses.isEmpty {
            nodeStatuses.last!.actualArrivalTime = arrivalTime
        }
    }

    func scheduleCurrentAirportDeparture(departureTime: Date) {
        if nodeStatuses.isEmpty {
            startTrip(departureTime: departureTime)
        } else {
            if currentAirportSequence < route.nodes.count {
                nodeStatuses.last!.actualDepartureTime = departureTime
                scheduleNextAirport()
            }
        }
    }

    func startTrip(departureTime: Date) {
        nodeStatuses.removeAll()
        nodeStatuses.append(
            TripNodeStatus(
                routeNode: currentRouteNode,
                sequence: currentAirportSequence,
                actualDepartureTime: departureTime
            )
        )

        scheduleNextAirport()
    }
}

@Model
class TripNodeStatus {
    @Attribute(.unique)
    var id: UUID
    var routeNode: RouteNode
    var sequence: Int
    var actualArrivalTime: Date?
    var actualDepartureTime: Date?

    func totalDelayMinutes(tripStartTime: Date) -> Int {
        if actualArrivalTime == nil {
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

    init(
        routeNode: RouteNode,
        sequence: Int,
        actualArrivalTime: Date? = nil,
        actualDepartureTime: Date? = nil
    ) {
        self.id = UUID()
        self.routeNode = routeNode
        self.sequence = sequence
        self.actualArrivalTime = actualArrivalTime
        self.actualDepartureTime = actualDepartureTime
    }
}

@Model
class Aircraft {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var trips: Set<Trip>

    var registrationNumber: String
    var type: String
    var seatingCapacity: Int
    var minimumStaffRequired: [StaffRole: Int]

    var totalTripsOperated: Int {
        return 0
    }

    var lastFlightDate: Date? {
        return nil
    }

    var currentStatus: AircraftStatus {
        return .available
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

    func isAvailable(for: Date, to: Date, availableStaff: [StaffRole: Int])
        -> Bool
    {
        return false
    }

}

@Model
class Staff: Hashable {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var trips: Set<Trip>

    var name: String
    var designation: StaffRole

    var totaltripHours: Double {
        return 0
    }

    var currentStatus: StaffAvailabilityStatus {
        return .available
    }

    init(name: String, designation: StaffRole) {
        self.id = UUID()
        self.name = name
        self.designation = designation
        self.trips = []
    }

    func isAvailable(for: Date, to: Date) -> Bool {
        return false
    }
}
