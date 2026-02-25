import Foundation
import SwiftData
import SwiftUI

@Observable
final class DemoDataSeeder {
    static let shared = DemoDataSeeder()

    private var updateTimer: Timer?
    private var reseedTimer: Timer?
    private var isSeeded = false
    private var delayedTripIDs: Set<UUID> = []
    private var modelContext: ModelContext?

    private var seedCount: Int {
        get {
            UserDefaults.standard.integer(forKey: "flightSeedCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "flightSeedCount")
        }
    }

    // MARK: - Public API

    func seedIfNeeded(in context: ModelContext) async {
        if isSeeded {
            return
        }

        // Check if data already exists in database
        if hasExistingData(in: context) {
            isSeeded = true
            return
        }
    }

    func startAutoUpdates(in context: ModelContext) {
        // Timer for flight progression every 5 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true)
        { [weak self] _ in
            self?.simulateFlightProgression(in: context)
        }
    }

    func stopAutoUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        reseedTimer?.invalidate()
        reseedTimer = nil
        
        modelContext = nil
    }



    // MARK: - Flight Simulator
    private func simulateFlightProgression(in context: ModelContext) {
        let currentTime = Date()

        do {
            // Fetch all trips
            let descriptor = FetchDescriptor<Trip>()
            let allTrips = try context.fetch(descriptor)

            for trip in allTrips {
                // Check if trip should start
                if !trip.isCancelled && !trip.isCompleted
                    && trip.nodeStatuses.isEmpty
                {
                    if trip.scheduledDepartureTime <= currentTime {
                        trip.startTrip(departureTime: currentTime)
                    }
                }

                // Progress ongoing trips
                if !trip.isCancelled && !trip.isCompleted
                    && !trip.nodeStatuses.isEmpty
                {
                    progressTrip(trip, currentTime: currentTime)
                }
            }

            try context.save()
        } catch {
            print("Error during flight simulation: \(error)")
        }
    }

    private func progressTrip(_ trip: Trip, currentTime: Date) {
        guard !trip.isCancelled && !trip.isCompleted else { return }

        let lastNodeStatus = trip.nodeStatuses.last

        if let lastNode = lastNodeStatus {
            // Check if we need to schedule arrival
            if lastNode.actualArrivalTime == nil {
                // Calculate planned arrival time based on the route node's offset
                var plannedArrivalTime = trip.scheduledDepartureTime
                    .addingTimeInterval(
                        TimeInterval(
                            lastNode.routeNode.plannedArrivalOffsetMinutes * 60
                        )
                    )

                // Add delay if this trip should have delays (5-10 minutes)
                if delayedTripIDs.contains(trip.id) {
                    let delayMinutes = Int.random(in: 5...10)
                    plannedArrivalTime = plannedArrivalTime.addingTimeInterval(
                        TimeInterval(delayMinutes * 60)
                    )
                }

                if currentTime >= plannedArrivalTime {
                    trip.scheduleCurrentAirportArrival(arrivalTime: currentTime)

                    // Check if this is not the last airport
                    if trip.currentAirportSequence < trip.route.nodes.count {
                        // Schedule departure after turnaround time (30 minutes)
                        let departureTime = currentTime.addingTimeInterval(30 * 60)
                        trip.scheduleCurrentAirportDeparture(departureTime: departureTime)
                    }
                }
            } else if lastNode.actualDepartureTime == nil {
                // Check if we need to schedule departure
                // Departure should happen after arrival + turnaround time
                if let arrivalTime = lastNode.actualArrivalTime {
                    let plannedDepartureTime = arrivalTime.addingTimeInterval(30 * 60)
                    
                    if currentTime >= plannedDepartureTime {
                        // Check if this is not the last airport
                        if trip.currentAirportSequence < trip.route.nodes.count {
                            trip.scheduleCurrentAirportDeparture(departureTime: currentTime)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func hasExistingData(in context: ModelContext) -> Bool {
        do {
            let airports = try context.fetch(FetchDescriptor<Airport>())
            let routes = try context.fetch(FetchDescriptor<Route>())
            let staff = try context.fetch(FetchDescriptor<Staff>())
            let aircrafts = try context.fetch(FetchDescriptor<Aircraft>())
            let trips = try context.fetch(FetchDescriptor<Trip>())

            return !airports.isEmpty || !routes.isEmpty || !staff.isEmpty
                || !aircrafts.isEmpty || !trips.isEmpty
        } catch {
            return false
        }
    }


}

// MARK: - Helper Function
func makeDemoDOB(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

extension String {
    func containsAny(_ elements: String...) -> Bool {
        elements.contains { self.contains($0) }
    }
}
