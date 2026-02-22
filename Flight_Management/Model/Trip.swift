import Foundation
import SwiftData

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
        if isCancelled {
            return .cancelled
        } else if isCompleted {
            return .completed
        } else if nodeStatuses.isEmpty {
            return .scheduled
        } else if totalDelayedMinutes > 0 {
            return .delayed
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
                if let totalTime = nodeStatuses[nodeStatuses.count - 1]
                    .actualDepartureTime
                {
                    return totalTime
                } else {
                    return arrivalTime
                }
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

    // route node for the current airport (1-based sequence)
    var plannedRouteNode: RouteNode {
        guard currentAirportSequence <= route.nodes.count, !route.nodes.isEmpty else {
            return route.nodes.last!
        }
        return route.nodes[currentAirportSequence - 1]
    }

    init(
        staff: [Staff],
        aircraft: Aircraft,
        nodeStatuses: [TripNodeStatus],
        route: Route,
        scheduledDepartureTime: Date,
        flightNumber: String,
        isCancelled: Bool = false
    ) {
        self.id = UUID()
        self.staffs = staff
        self.aircraft = aircraft
        self.nodeStatuses = []
        self.route = route
        self.scheduledDepartureTime = scheduledDepartureTime
        self.flightNumber = flightNumber
        self.isCancelled = isCancelled
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
    /// Cancel trip (before start or midway). Updates staff and aircraft last/current/next trip state.
    func cancel() {
        guard !isCancelled, !isCompleted else { return }

        let hasStarted = !nodeStatuses.isEmpty

        // Update aircraft: clear current, set last if started, recompute next
        if aircraft.currentTrip?.id == id {
            aircraft.currentTrip = nil
        }
        if hasStarted {
            aircraft.lastCompletedTrip = self
        }
        aircraft.updateNextScheduledTrip(after: self)

        // Update staff: clear current, set last if started, recompute next
        for staff in staffs {
            if staff.currentTrip?.id == id {
                staff.currentTrip = nil
            }
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
        if actualArrivalTime == nil && actualDepartureTime == nil {
            return 0
        }
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
