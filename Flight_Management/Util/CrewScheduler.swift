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
        var replacementCrewIds: Set<UUID> = []

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
            replacementCrewIds.formUnion(candidateCrewIds)
            return !candidateCrewIds.isDisjoint(with: overlappingCrewIds)
        }

        let sortedAffectedTrips = affectedTrips.sorted {
            $0.scheduledDepartureTime < $1.scheduledDepartureTime
        }
        
        for trip in sortedAffectedTrips {
            resolveCrewForUpcomingTrip(
                trip,
                delayedCrewIds: replacementCrewIds,
                allStaff: allStaff,
                blockingArrival: delayedArrival
            )
        }
    }
    
    private static func resolveCrewForUpcomingTrip(
        _ trip: Trip,
        delayedCrewIds: Set<UUID>,
        allStaff: [Staff],
        blockingArrival: Date
    ) {
        let start = trip.scheduledDepartureTime
        let end = start.addingTimeInterval(TimeInterval(trip.route.totalPlannedDurationMinutes * 60))

        var updatedCrew = trip.staffs.filter { !delayedCrewIds.contains($0.id) }

        let conflictedByRole = Dictionary(
            grouping: trip.staffs.filter { delayedCrewIds.contains($0.id) },
            by: \.designation
        )

        for (role, conflicted) in conflictedByRole {
            let needed = conflicted.count
            let candidates = allStaff.filter { staff in
                !delayedCrewIds.contains(staff.id)
                    && !updatedCrew.contains { $0.id == staff.id }
                    && staff.designation == role
                    && staff.isAvailable(from: start, to: end)
            }
            guard candidates.count >= needed else {
                delayTrip(trip, blockedUntil: blockingArrival)
                return
            }
            updatedCrew.append(contentsOf: candidates.prefix(needed))
        }

        reassignCrew(of: trip, to: updatedCrew)
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
        guard blockedUntil >= trip.scheduledDepartureTime else { return }
        trip.scheduledDepartureTime = blockedUntil
    }
}

