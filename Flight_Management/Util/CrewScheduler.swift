import Foundation
import SwiftData

struct CrewScheduler {

    static func handleDelayPropagation(
        delayedTrip: Trip,
        in context: ModelContext,
        now: Date = Date()
    ) {
        do {
            let tripsDescriptor = FetchDescriptor<Trip>(
                predicate: #Predicate {
                    !$0.isCancelled && !$0.isCompleted
                }
            )
            let staffDescriptor = FetchDescriptor<Staff>(
                predicate: #Predicate {
                    !$0.isMarkedUnavailable
                }
            )

            let allTrips = try context.fetch(tripsDescriptor)
            let allStaff = try context.fetch(staffDescriptor)

            handleDelayPropagation(
                delayedTrip: delayedTrip,
                allTrips: allTrips,
                allStaff: allStaff,
                now: now
            )

            try? context.save()
        } catch {
            print("❌ CrewScheduler failed: \(error)")
        }
    }

    static func handleDelayPropagation(
        delayedTrip: Trip,
        allTrips: [Trip],
        allStaff: [Staff],
        now: Date = Date()
    ) {
        let delayedArrival = delayedTrip.estimatedArrivalTime

        let overlappingCrewIds = Set(delayedTrip.staffs.map { $0.id })

        let affectedTrips = allTrips.filter { candidate in
            guard !candidate.isCancelled,
                  !candidate.isCompleted,
                  candidate.id != delayedTrip.id
            else { return false }

            guard candidate.nodeStatuses.isEmpty else { return false }

            guard candidate.scheduledDepartureTime >= now else { return false }

            guard candidate.scheduledDepartureTime < delayedArrival else {
                return false
            }
            
            // delayed trip share at-least one crew which is scheduled for
            // just next trip
            let candidateCrewIds = Set(candidate.staffs.map { $0.id })
            return !candidateCrewIds.isDisjoint(with: overlappingCrewIds)
        }

        for trip in affectedTrips {
            resolveCrewForUpcomingTrip(
                trip,
                allStaff: allStaff,
                blockingArrival: delayedArrival
            )
        }
    }
    
    private static func resolveCrewForUpcomingTrip(
        _ trip: Trip,
        allStaff: [Staff],
        blockingArrival: Date
    ) {
        let start = trip.scheduledDepartureTime
        let end = start.addingTimeInterval(
            TimeInterval(trip.route.totalPlannedDurationMinutes * 60)
        )

        var newCrew: [Staff] = []

        for (role, requiredCount) in trip.aircraft.minimumStaffRequired
        where requiredCount > 0 {
            let candidates = allStaff.filter { staff in
                staff.designation == role
                    && staff.isAvailable(from: start, to: end)
            }

            guard candidates.count >= requiredCount else {
                // Not enough replacement crew – delay this trip.
                delayTrip(trip, blockedUntil: blockingArrival)
                return
            }

            newCrew.append(contentsOf: candidates.prefix(requiredCount))
        }

        reassignCrew(of: trip, to: newCrew)
    }

    private static func reassignCrew(of trip: Trip, to newCrew: [Staff]) {
        let oldCrew = trip.staffs

        // Detach from old crew.
        for staff in oldCrew {
            staff.trips.removeAll { $0.id == trip.id }
            if staff.nextScheduledTrip?.id == trip.id {
                staff.updateNextScheduledTrip(after: trip)
            }
        }

        // Attach to new crew.
        trip.staffs = newCrew
        for staff in newCrew where !staff.trips.contains(where: { $0.id == trip.id }) {
            staff.trips.append(trip)
            staff.updateNextScheduledTrip(after: trip)
        }
    }

    private static func delayTrip(_ trip: Trip, blockedUntil: Date) {
        guard blockedUntil > trip.scheduledDepartureTime else { return }
        trip.scheduledDepartureTime = blockedUntil
    }
}

