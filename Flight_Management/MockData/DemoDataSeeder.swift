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
        // Clean existing demo data optionally - we keep existing app data

        // 1. Airports
        let airports = self.createAirports()
        airports.forEach { context.insert($0) }

        // 2. Aircrafts
        let aircrafts = self.createAircrafts()
        aircrafts.forEach { context.insert($0) }

        // 3. Staffs
        let staffs = self.createStaffs()
        staffs.forEach { context.insert($0) }

        // 4. Routes
        let routes = self.createRoutes(using: airports)
        routes.forEach { context.insert($0) }

        // 5. Create scheduled trips (10)
        let trips = self.createTrips(routes: routes, aircrafts: aircrafts, staffs: staffs)
        trips.forEach { context.insert($0) }

        // Save
        do {
            try context.save()
        } catch {
            print("DemoDataSeeder: failed to save context: \(error)")
        }
    }

    // MARK: - Random updates (demo)

    @MainActor
    private func performRandomTripUpdates(in context: ModelContext) async {
        let fetch: FetchDescriptor<Trip> = FetchDescriptor<Trip>()
        guard let trips = try? context.fetch(fetch) as? [Trip], !trips.isEmpty else { return }

        for trip in trips.shuffled().prefix(3) {
            if trip.isCompleted { continue }

            let rand = Int.random(in: 0...100)
            if rand < 10 {
                trip.cancel()
            } else if rand < 40 {
                let delay = Int.random(in: 5...40)
                if trip.nodeStatuses.isEmpty {
                    trip.startTrip(departureTime: Date().addingTimeInterval(TimeInterval(delay * 60)))
                } else {
                    if let lastIndex = trip.nodeStatuses.indices.last {
                        trip.nodeStatuses[lastIndex].actualArrivalTime = Date().addingTimeInterval(TimeInterval(delay * 60))
                    }
                }
            } else {
                if trip.nodeStatuses.isEmpty {
                    trip.startTrip(departureTime: Date())
                } else if !trip.isCompleted && Bool.random() {
                    trip.scheduleCurrentAirportArrival(arrivalTime: Date())
                }
            }
        }

        do { try context.save() } catch { print("DemoDataSeeder.update: failed saving - \\(error)") }
    }

    // MARK: - Helpers to create mock model objects

    private func createAirports() -> [Airport] {
        let iataCodes = [
            "JFK","LHR","CDG","DXB","HND","SIN","LAX","ORD","DFW","FRA",
            "AMS","MAD","BKK","SYD","YYZ","SFO","MIA","SEA","DEN","BOM",
            "GRU","NRT","ICN","DME","PEK","CAI","MEX","SVO","IAD","DUB"
        ]

        return iataCodes.map { code in
            Airport(code: code, name: "\(code) International", city: "City \(code)", country: "Country \(code)")
        }
    }

    private func createAircrafts() -> [Aircraft] {
        var models: [String] = []
        for i in 1...30 {
            models.append("Boeing 737-\(100 + i)")
        }

        return models.map { model in
            let seating = Int.random(in: 120...320)
            let mins: [StaffRole: Int] = [.pilot: 2, .coPilot: 2, .cabinCrew: max(4, seating / 50)]
            return Aircraft(registrationNumber: "A\(Int.random(in: 1000...9999))", type: model, seatingCapacity: seating, minimumStaffRequired: mins)
        }
    }

    private func createStaffs() -> [Staff] {
        var staffs: [Staff] = []
        // 10 pilots
        for i in 1...10 {
            let name = "Pilot \(i)"
            staffs.append(Staff(name: name, designation: .pilot, gender: .male, email: "pilot\(i)@demo.com", profileImage: nil, dob: Calendar.current.date(byAdding: .year, value: -Int.random(in: 35...60), to: Date())!))
        }
        // 10 copilots
        for i in 1...10 {
            let name = "CoPilot \(i)"
            staffs.append(Staff(name: name, designation: .coPilot, gender: .male, email: "copilot\(i)@demo.com", profileImage: nil, dob: Calendar.current.date(byAdding: .year, value: -Int.random(in: 30...55), to: Date())!))
        }
        // 20 cabin crew
        for i in 1...20 {
            let name = "Crew \(i)"
            staffs.append(Staff(name: name, designation: .cabinCrew, gender: .female, email: "crew\(i)@demo.com", profileImage: nil, dob: Calendar.current.date(byAdding: .year, value: -Int.random(in: 25...50), to: Date())!))
        }

        return staffs
    }

    private func createRoutes(using airports: [Airport]) -> [Route] {
        var routes: [Route] = []
        let airportPool = airports
        for i in 0..<10 {
            let nodeCount = Int.random(in: 3...5)
            var selected: [Airport] = []
            var attempts = 0
            while selected.count < nodeCount && attempts < 50 {
                attempts += 1
                let a = airportPool.randomElement()!
                if !selected.contains(where: { $0.code == a.code }) {
                    selected.append(a)
                }
            }

            let route = Route(name: "Route \(i+1)")
            for airport in selected {
                route.addNode(airport: airport, journeyTimeMinutes: Int.random(in: 30...180), turnAroundTimeMinutes: 30)
            }
            routes.append(route)
        }
        return routes
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
