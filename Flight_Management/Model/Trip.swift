import Foundation
import SwiftData

@Model
class Trip {
    @Attribute(.unique)
    var id: UUID
    @Attribute(.unique)
    var tripNumber: String

    @Relationship(deleteRule: .nullify, inverse: \Staff.trips)
    var staffs: [Staff]
    @Relationship(deleteRule: .nullify, inverse: \Aircraft.trips)
    var aircraft: Aircraft
    @Relationship(deleteRule: .cascade)
    var nodeStatuses: [TripNodeStatus]

    var route: Route
    var scheduledDepartureTime: Date
    var tripNumberSearchKey: String
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

    // The TripNodeStatus for the airport the trip is currently flying toward.
    var activeNodeStatus: TripNodeStatus? {
        nodeStatuses.first { $0.routeNode.sequence == currentAirportSequence }
    }

    private var latestNodeStatus: TripNodeStatus? {
        nodeStatuses.max { $0.routeNode.sequence < $1.routeNode.sequence }
    }

    var totalDelayedMinutes: Int {
        guard !nodeStatuses.isEmpty else { return 0 }
        return nodeStatuses
            .map { $0.totalDelayMinutes(tripStartTime: scheduledDepartureTime) }
            .max() ?? 0
    }

    var actualDepartureTime: Date? {
        // The first TripNodeStatus represents the source airport node.
        let sorted = nodeStatuses.sorted { $0.routeNode.sequence < $1.routeNode.sequence }
        return sorted.first?.actualDepartureTime
    }

    // estimated arrival time (cancellation and delay were considered)
    var estimatedArrivalTime: Date {
        let arrivalTime = scheduledDepartureTime.addingTimeInterval(
            TimeInterval(route.totalPlannedDurationMinutes * 60)
        )

        if isCancelled && nodeStatuses.isEmpty {
            // trip cancelled before starting
            return scheduledDepartureTime
        } else if nodeStatuses.isEmpty {
            // trip not started yet
            return arrivalTime
        } else if isCancelled {
            // Sort by sequence so we reliably get the last visited node
            // regardless of SwiftData's relationship array ordering
            let sorted = nodeStatuses.sorted {
                $0.routeNode.sequence < $1.routeNode.sequence
            }
            if let last = sorted.last, last.actualArrivalTime != nil {
                // cancelled after landing at an intermediate airport
                if sorted.count > 1,
                    let dep = sorted[sorted.count - 2].actualDepartureTime
                {
                    return dep
                } else {
                    return arrivalTime
                }
            } else {
                // cancelled while in flight
                return sorted.last?.actualArrivalTime ?? arrivalTime
            }
        }

        // trip is ongoing
        return arrivalTime.addingTimeInterval(
            TimeInterval(totalDelayedMinutes * 60)
        )
    }

    // route node for the current airport (1-based sequence)
    var plannedRouteNode: RouteNode {
        let sorted = route.nodes.sorted { $0.sequence < $1.sequence }
        guard !sorted.isEmpty else { return route.nodes.last! }
        let index = min(currentAirportSequence - 1, sorted.count - 1)
        return sorted[index]
    }

    init(
        staff: [Staff],
        aircraft: Aircraft,
        nodeStatuses: [TripNodeStatus],
        route: Route,
        scheduledDepartureTime: Date,
        tripNumber: String,
        isCancelled: Bool = false
    ) {
        self.id = UUID()
        self.staffs = staff
        self.aircraft = aircraft
        self.nodeStatuses = []
        self.route = route
        self.scheduledDepartureTime = scheduledDepartureTime
        self.tripNumber = tripNumber
        self.tripNumberSearchKey = Trip.normalisedSearchKey(from: tripNumber)
        self.isCancelled = isCancelled
    }

}

// MARK: Util
extension Trip {
    static func normalisedSearchKey(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        let filtered =
            trimmed
            .filter { $0.isLetter || $0.isNumber }

        return String(filtered).lowercased()
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
        guard let active = activeNodeStatus else { return }

        active.actualArrivalTime = arrivalTime

        // trip is completed and aircraft is arrived at the last airport of route
        if currentAirportSequence == route.nodes.count {
            aircraft.updateLastAndNextScheduledTrip(completedTrip: self)
            for staff in staffs {
                staff.updateLastAndNextScheduledTrip(completedTrip: self)
            }
            isCompleted = true
        }
    }

    func scheduleCurrentAirportDeparture(departureTime: Date) {
        if isCancelled {
            return
        }

        if nodeStatuses.isEmpty {
            startTrip(departureTime: departureTime)
        } else {
            // takeoff from current airport and prepare the next one
            if !isCompleted, let active = activeNodeStatus {
                active.actualDepartureTime = departureTime
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

        aircraft.startTrip(self)
        for staff in staffs {
            staff.startTrip(self)
        }

        scheduleNextAirport()
    }

}

// MARK: Cancel Trip
extension Trip {
    // Cancel trip (before start or midway). Updates staff and aircraft last/current/next trip state.
    func cancel() {
        guard !isCancelled, !isCompleted else { return }

        let hasStarted = !nodeStatuses.isEmpty

        // Update aircraft: clear current, set last if started, recompute next
        if aircraft.currentTrip?.id == id {
            aircraft.currentTrip = nil
        }
        if hasStarted {
            aircraft.lastCompletedTrip = self
            aircraft.addTripHours(for: self)
        }
        aircraft.updateNextScheduledTrip(after: self)

        // Update staff: clear current, set last if started, recompute next
        for staff in staffs {
            if staff.currentTrip?.id == id {
                staff.currentTrip = nil
            }
            if hasStarted {
                staff.lastCompletedTrip = self
                staff.addTripHours(for: self)
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

        guard actualArrivalTime != nil || actualDepartureTime != nil else {
            return 0
        }

        // Source node (no arrival yet)
        if actualArrivalTime == nil {

            guard let actualDeparture = actualDepartureTime else {
                return 0
            }

            let plannedDeparture = tripStartTime

            let delay = actualDeparture.timeIntervalSince(plannedDeparture)

            return max(0, Int(delay / 60))
        }

        // Other nodes
        guard let actualArrival = actualArrivalTime else {
            return 0
        }

        let plannedArrival = tripStartTime.addingTimeInterval(
            TimeInterval(routeNode.plannedArrivalOffsetMinutes * 60)
        )

        let delay = actualArrival.timeIntervalSince(plannedArrival)

        return max(0, Int(delay / 60))
    }

}
