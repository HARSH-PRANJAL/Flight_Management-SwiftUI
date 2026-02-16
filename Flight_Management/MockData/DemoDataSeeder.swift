import Foundation
import SwiftData
import SwiftUI

/// DemoDataSeeder
/// - Modular seeder for inserting mock airports, aircrafts, staff, routes and trips into a ModelContext.
/// - Designed to be detachable: call `seed(in:)` to insert data and `startAutoUpdates(in:)` to begin status updates every 2 minutes.
/// - For demo/testing only — schedules trips relative to `Date()` so they change each app restart.

public final class DemoDataSeeder {
    public static let shared = DemoDataSeeder()

    private var updateTask: Task<Void, Never>? = nil
    // count how many scheduled trips we've auto-started (one per tick)
    private var initialAutoStarted: Int = 0
    private var isSeedingKey = "DemoDataSeeder.seeded"

    public init() {}

    // MARK: - Public API

    /// Seed demo data. Safe to call multiple times - will not reseed if already seeded in UserDefaults.
    public func seedIfNeeded(in context: ModelContext, force: Bool = false) async {
        let already = UserDefaults.standard.bool(forKey: isSeedingKey)
        if already && !force { return }
        await seed(in: context)
        UserDefaults.standard.set(true, forKey: isSeedingKey)
    }

    /// Force reseed (clears flag and runs seed)
    public func forceReseed(in context: ModelContext) async {
        UserDefaults.standard.set(false, forKey: isSeedingKey)
        await seed(in: context)
        UserDefaults.standard.set(true, forKey: isSeedingKey)
    }

    /// Start periodic updates that randomly update trip states every 2 minutes.
    /// Call `stopAutoUpdates()` to cancel.
    public func startAutoUpdates(in context: ModelContext) {
        stopAutoUpdates()
        updateTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                await MainActor.run {
                    Task {
                        await self.performRandomTripUpdates(in: context)
                    }
                }
                do {
                    try await Task.sleep(nanoseconds: 2 * 60 * 1_000_000_000) // 2 minutes
                } catch {
                    break
                }
            }
        }
    }

    public func stopAutoUpdates() {
        updateTask?.cancel()
        updateTask = nil
    }

    // MARK: - Core Seeding

    @MainActor
    private func seed(in context: ModelContext) async {
        // Remove all existing demo objects so we reconstruct clean demo data
        do {
            let allTrips: FetchDescriptor<Trip> = FetchDescriptor<Trip>()
            let trips = (try? context.fetch(allTrips)) as? [Trip] ?? []
            for t in trips { context.delete(t) }

            let allRoutes: FetchDescriptor<Route> = FetchDescriptor<Route>()
            let routes = (try? context.fetch(allRoutes)) as? [Route] ?? []
            for r in routes { context.delete(r) }

            let allAircraft: FetchDescriptor<Aircraft> = FetchDescriptor<Aircraft>()
            let aircraftsExisting = (try? context.fetch(allAircraft)) as? [Aircraft] ?? []
            for a in aircraftsExisting { context.delete(a) }

            let allStaff: FetchDescriptor<Staff> = FetchDescriptor<Staff>()
            let staffsExisting = (try? context.fetch(allStaff)) as? [Staff] ?? []
            for s in staffsExisting { context.delete(s) }

            let allAirports: FetchDescriptor<Airport> = FetchDescriptor<Airport>()
            let airportsExisting = (try? context.fetch(allAirports)) as? [Airport] ?? []
            for ap in airportsExisting { context.delete(ap) }

            try context.save()
        } catch {
            print("DemoDataSeeder: failed clearing existing demo data: \(error)")
        }

        // 1. Airports (4)
        let airports = self.createAirports()
        airports.forEach { context.insert($0) }

        // 2. Aircrafts (3)
        let aircrafts = self.createAircrafts()
        aircrafts.forEach { context.insert($0) }

        // 3. Staffs (3 pilots, 3 copilots, 10 crew)
        let staffs = self.createStaffs()
        staffs.forEach { context.insert($0) }

        // 4. Routes (3 with specific node orders)
        let routes = self.createRoutes(using: airports)
        routes.forEach { context.insert($0) }

        // 5. Create initial trips: 3 immediate scheduled trips (now +10, +20, +30 min)
        let initialTrips = self.createInitialTrips(routes: routes, aircrafts: aircrafts, staffs: staffs)
        initialTrips.forEach { context.insert($0) }

        // 6. Schedule 5 additional trips across next 10 days ensuring availability
        let futureTrips = self.createFutureTrips(routes: routes, aircrafts: aircrafts, staffs: staffs)
        futureTrips.forEach { context.insert($0) }

        // Save and start simulator
        do {
            try context.save()
            startAutoUpdates(in: context)
        } catch {
            print("DemoDataSeeder: failed to save context: \(error)")
        }
    }

    // MARK: - Random updates (demo)

    @MainActor
    private func performRandomTripUpdates(in context: ModelContext) async {
        let fetch: FetchDescriptor<Trip> = FetchDescriptor<Trip>()
        guard let trips = try? context.fetch(fetch) as? [Trip], !trips.isEmpty else { return }

        let now = Date()

        print("DemoDataSeeder.tick: performing update at \(now); totalTrips=\(trips.count)")

        // Start one scheduled trip per tick (to simulate staggered starts)
        let scheduledTrips = trips.filter { $0.currentStatus == .scheduled && !$0.isCancelled }
            .sorted { $0.scheduledDepartureTime < $1.scheduledDepartureTime }

        if initialAutoStarted < scheduledTrips.count {
            let tripToStart = scheduledTrips[initialAutoStarted]
            print("DemoDataSeeder: auto-starting trip \(tripToStart.flightNumber) scheduled=\(tripToStart.scheduledDepartureTime) index=\(initialAutoStarted)")
            tripToStart.startTrip(departureTime: Date())
            initialAutoStarted += 1
        }

        // For ongoing trips, simulate arrival/departure actions every tick
        for trip in trips {
            if trip.isCompleted || trip.isCancelled { continue }

            if !trip.nodeStatuses.isEmpty && !trip.isCompleted {
                let rand = Int.random(in: 0...100)
                if rand < 15 {
                    // small chance to introduce delay
                    let delay = Int.random(in: 3...10)
                    print("DemoDataSeeder: trip \(trip.flightNumber) - introducing delay of \(delay) mins")
                    if let lastIndex = trip.nodeStatuses.indices.last {
                        trip.nodeStatuses[lastIndex].actualArrivalTime = Date().addingTimeInterval(TimeInterval(delay * 60))
                    }
                } else if rand < 60 {
                    // schedule arrival at current airport
                    print("DemoDataSeeder: trip \(trip.flightNumber) - scheduling arrival")
                    trip.scheduleCurrentAirportArrival(arrivalTime: Date())
                } else {
                    // schedule departure from current airport
                    print("DemoDataSeeder: trip \(trip.flightNumber) - scheduling departure")
                    trip.scheduleCurrentAirportDeparture(departureTime: Date())
                }
            }
        }

        do { try context.save() } catch { print("DemoDataSeeder.update: failed saving - \\(error)") }
    }

    // MARK: - Helpers to create mock model objects

    private func createAirports() -> [Airport] {
        // Create 4 airports used in demo routes
        let codes = ["JFK", "LAX", "SFO", "ORD"]
        return codes.map { code in
            Airport(code: code, name: "\(code) International", city: "City \(code)", country: "Country \(code)")
        }
    }

    private func createAircrafts() -> [Aircraft] {
        // Create 3 aircrafts with minimal staff requirements: 1 pilot, 1 copilot, 2 crew
        var list: [Aircraft] = []
        for i in 1...3 {
            let reg = "AC\(100 + i)"
            let type = "DemoPlane-\(i)"
            let seating = 120 + i * 10
            let mins: [StaffRole: Int] = [.pilot: 1, .coPilot: 1, .cabinCrew: 2]
            list.append(Aircraft(registrationNumber: reg, type: type, seatingCapacity: seating, minimumStaffRequired: mins))
        }
        return list
    }

    private func createStaffs() -> [Staff] {
        var staffs: [Staff] = []
        // 3 pilots
        for i in 1...3 {
            let name = "Pilot \(i)"
            staffs.append(Staff(name: name, designation: .pilot, gender: .male, email: "pilot\(i)@demo.com", profileImage: nil, dob: Calendar.current.date(byAdding: .year, value: -30 - i, to: Date())!))
        }
        // 3 copilots
        for i in 1...3 {
            let name = "CoPilot \(i)"
            staffs.append(Staff(name: name, designation: .coPilot, gender: .male, email: "copilot\(i)@demo.com", profileImage: nil, dob: Calendar.current.date(byAdding: .year, value: -28 - i, to: Date())!))
        }
        // 10 cabin crew
        for i in 1...10 {
            let name = "Crew \(i)"
            staffs.append(Staff(name: name, designation: .cabinCrew, gender: .female, email: "crew\(i)@demo.com", profileImage: nil, dob: Calendar.current.date(byAdding: .year, value: -25 - i, to: Date())!))
        }

        return staffs
    }

    private func createRoutes(using airports: [Airport]) -> [Route] {
        // Create 3 specific routes based on the provided airport ordering
        // route1: 1->2->3
        // route2: 2->4->3->1
        // route3: 1->3->4->2
        var routes: [Route] = []
        guard airports.count >= 4 else { return routes }

        let r1 = Route(name: "Route 1")
        r1.addNode(airport: airports[0], journeyTimeMinutes: 60)
        r1.addNode(airport: airports[1], journeyTimeMinutes: 90)
        r1.addNode(airport: airports[2], journeyTimeMinutes: 120)

        let r2 = Route(name: "Route 2")
        r2.addNode(airport: airports[1], journeyTimeMinutes: 50)
        r2.addNode(airport: airports[3], journeyTimeMinutes: 70)
        r2.addNode(airport: airports[2], journeyTimeMinutes: 80)
        r2.addNode(airport: airports[0], journeyTimeMinutes: 100)

        let r3 = Route(name: "Route 3")
        r3.addNode(airport: airports[0], journeyTimeMinutes: 45)
        r3.addNode(airport: airports[2], journeyTimeMinutes: 85)
        r3.addNode(airport: airports[3], journeyTimeMinutes: 75)
        r3.addNode(airport: airports[1], journeyTimeMinutes: 95)

        routes.append(contentsOf: [r1, r2, r3])
        return routes
    }

    private func createInitialTrips(routes: [Route], aircrafts: [Aircraft], staffs: [Staff]) -> [Trip] {
        var created: [Trip] = []
        let now = Date()
        let offsets = [10, 20, 30] // minutes

        for (idx, route) in routes.enumerated() where idx < offsets.count {
            let start = Calendar.current.date(byAdding: .minute, value: offsets[idx], to: now) ?? now
            // pick an available aircraft and staff similar to createTrips
            if let (aircraft, staffList) = findResources(for: route, at: start, aircrafts: aircrafts, staffs: staffs) {
                let flightNumber = "RT\(100 + idx)"
                let trip = Trip(staff: staffList, aircraft: aircraft, nodeStatuses: [], route: route, scheduledDepartureTime: start, flightNumber: flightNumber, isCancelled: false)
                aircraft.trips.append(trip)
                route.trips.append(trip)
                for s in staffList { s.trips.append(trip) }
                created.append(trip)
            }
        }

        return created
    }

    private func createFutureTrips(routes: [Route], aircrafts: [Aircraft], staffs: [Staff]) -> [Trip] {
        var created: [Trip] = []
        let now = Date()

        // pick 5 different days in next 10 days
        var dayOffsets = Array(1...10).shuffled().prefix(5)
        var i = 0
        for day in dayOffsets {
            let minuteOffset = 9 + i * 60 // vary time
            let start = Calendar.current.date(byAdding: .day, value: day, to: now) ?? now
            let startWithTime = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: start) ?? start

            let route = routes[i % routes.count]
            if let (aircraft, staffList) = findResources(for: route, at: startWithTime, aircrafts: aircrafts, staffs: staffs) {
                let flightNumber = "FT\(200 + i)"
                let trip = Trip(staff: staffList, aircraft: aircraft, nodeStatuses: [], route: route, scheduledDepartureTime: startWithTime, flightNumber: flightNumber, isCancelled: false)
                aircraft.trips.append(trip)
                route.trips.append(trip)
                for s in staffList { s.trips.append(trip) }
                created.append(trip)
            }
            i += 1
        }

        return created
    }

    // helper to find available aircraft and staff for a route at a given time
    private func findResources(for route: Route, at start: Date, aircrafts: [Aircraft], staffs: [Staff]) -> (Aircraft, [Staff])? {
        let duration = TimeInterval(route.totalPlannedDurationMinutes * 60)
        let end = start.addingTimeInterval(duration)

        guard let aircraft = aircrafts.first(where: { ac in
            return !ac.trips.contains(where: { existing in
                let existingStart = existing.scheduledDepartureTime
                let existingEnd = existing.estimatedArrivalTime
                return existingEnd > start && existingStart < end
            })
        }) else { return nil }

        guard let pilot = staffs.first(where: { s in s.designation == .pilot && !s.trips.contains(where: { t in t.estimatedArrivalTime > start && t.scheduledDepartureTime < end }) }) else { return nil }
        guard let copilot = staffs.first(where: { s in s.designation == .coPilot && !s.trips.contains(where: { t in t.estimatedArrivalTime > start && t.scheduledDepartureTime < end }) }) else { return nil }

        let requiredCabin = aircraft.minimumStaffRequired[.cabinCrew] ?? 2
        let availableCrew = staffs.filter { s in s.designation == .cabinCrew && !s.trips.contains(where: { t in t.estimatedArrivalTime > start && t.scheduledDepartureTime < end }) }
        if availableCrew.count < requiredCabin { return nil }

        let crewMembers = Array(availableCrew.prefix(requiredCabin))
        var staffList: [Staff] = [pilot, copilot]
        staffList.append(contentsOf: crewMembers)

        return (aircraft, staffList)
    }

    private func createTrips(routes: [Route], aircrafts: [Aircraft], staffs: [Staff]) -> [Trip] {
        var created: [Trip] = []
        let now = Date()

        // We'll try to schedule 10 trips for today with non-overlapping resources.
        var aircraftPool = aircrafts

        for i in 0..<10 {
            let offsetMinutes = 10 + i * 40 // larger spacing to reduce overlap
            let start = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: now) ?? now

            let route = routes[i % routes.count]
            let duration = TimeInterval(route.totalPlannedDurationMinutes * 60)
            let end = start.addingTimeInterval(duration)

            // find an aircraft that has no overlapping trips
            guard let aircraft = aircraftPool.first(where: { ac in
                return !ac.trips.contains(where: { existing in
                    let existingStart = existing.scheduledDepartureTime
                    let existingEnd = existing.estimatedArrivalTime
                    return existingEnd > start && existingStart < end
                })
            }) else {
                // if none found, skip this slot
                continue
            }

            // pick pilot and copilot available
            guard let pilot = staffs.first(where: { s in s.designation == .pilot && !s.trips.contains(where: { t in t.estimatedArrivalTime > start && t.scheduledDepartureTime < end }) }) else { continue }
            guard let copilot = staffs.first(where: { s in s.designation == .coPilot && !s.trips.contains(where: { t in t.estimatedArrivalTime > start && t.scheduledDepartureTime < end }) }) else { continue }

            // pick required cabin crew
            let requiredCabin = aircraft.minimumStaffRequired[.cabinCrew] ?? 4
            let availableCrew = staffs.filter { s in s.designation == .cabinCrew && !s.trips.contains(where: { t in t.estimatedArrivalTime > start && t.scheduledDepartureTime < end }) }
            if availableCrew.count < requiredCabin { continue }

            let crewMembers = Array(availableCrew.prefix(requiredCabin))

            var staffList: [Staff] = [pilot, copilot]
            staffList.append(contentsOf: crewMembers)

            let flightNumber = "FL\(100 + i)"
            let trip = Trip(staff: staffList, aircraft: aircraft, nodeStatuses: [], route: route, scheduledDepartureTime: start, flightNumber: flightNumber, isCancelled: false)

            // maintain relations so future checks see this trip
            aircraft.trips.append(trip)
            route.trips.append(trip)
            for s in staffList { s.trips.append(trip) }

            created.append(trip)
        }

        return created
    }
}
