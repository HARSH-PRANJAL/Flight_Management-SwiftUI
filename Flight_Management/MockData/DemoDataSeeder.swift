import Foundation
import PhotosUI
import SwiftData

@Observable
final class DemoDataSeeder {
    static let shared = DemoDataSeeder()

    private var updateTimer: Timer?
    private var isSeeded = false
    private var delayedTripIDs: Set<UUID> = []

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

        await forceReseed(in: context)
    }

    func forceReseed(in context: ModelContext) async {
        // Increment seed count for sequential naming
        seedCount += 1

        // Check if we already have data - if so, just add new trips
        let hasExistingData = hasExistingData(in: context)

        if hasExistingData {
            do {
                let descriptor1 = FetchDescriptor<Airport>()
                let airports = try context.fetch(descriptor1)

                for airport in airports {
                    context.delete(airport)
                }

                let descriptor2 = FetchDescriptor<Aircraft>()
                let aircrafts = try context.fetch(descriptor2)

                for aircraft in aircrafts {
                    context.delete(aircraft)
                }

                let descriptor3 = FetchDescriptor<Staff>()
                let staffs = try context.fetch(descriptor3)

                for staff in staffs {
                    context.delete(staff)
                }

                let descriptor4 = FetchDescriptor<Trip>()
                let trips = try context.fetch(descriptor4)

                for trip in trips {
                    context.delete(trip)
                }

                let descriptor5 = FetchDescriptor<Route>()
                let routes = try context.fetch(descriptor5)

                for route in routes {
                    context.delete(route)
                }

                try context.save()
                print("____________deleted previous data_________________")
            } catch {
                print("ERROR: Cannot reset demo data: \(error)")
            }
            await seedIfNeeded(in: context)
        }

        // Create fresh data if nothing exists
        let airports = createIndianAirports()
        let aircrafts = createAircrafts()
        let staff = createStaff()
        let routes = createRoutes(with: airports)
        let trips = createTrips(
            routes: routes,
            aircrafts: aircrafts,
            staff: staff,
            currentDate: Date()
        )

        // Insert all data
        for airport in airports {
            context.insert(airport)
        }
        for aircraft in aircrafts {
            context.insert(aircraft)
        }
        for staffMember in staff {
            context.insert(staffMember)
        }
        for route in routes {
            context.insert(route)
        }
        for trip in trips {
            context.insert(trip)
        }

        do {
            try context.save()
            isSeeded = true
            printSeedingData(
                airports: airports,
                aircrafts: aircrafts,
                staff: staff,
                routes: routes,
                trips: trips
            )
        } catch {
            print("Failed to seed demo data: \(error)")
        }
    }

    func startAutoUpdates(in context: ModelContext) {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true)
        { [weak self] _ in
            self?.simulateFlightProgression(in: context)
        }
    }

    private func imageData(fromAssetName name: String) -> Data? {
        guard let image = UIImage(named: name) else {
            print("⚠️ Missing asset: \(name)")
            return nil
        }

        return image.jpegData(compressionQuality: 0.78)
    }

    func stopAutoUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Data Creation

    private func createIndianAirports() -> [Airport] {
        let airportData: [(code: String, name: String, city: String)] = [
            ("DEL", "Indira Gandhi International", "Delhi"),
            ("BOM", "Bombay High", "Mumbai"),
            ("BLR", "Kempegowda International", "Bangalore"),
            ("HYD", "Rajiv Gandhi International", "Hyderabad"),
            ("MAA", "Chennai International", "Chennai"),
            ("COK", "Cochin International", "Kochi"),
            ("PNQ", "Pune Airport", "Pune"),
            ("AMD", "Sardar Vallabhbhai Patel International", "Ahmedabad"),
            ("GOI", "Dabolim Airport", "Goa"),
            ("CCU", "Netaji Subhas Chandra Bose International", "Kolkata"),
            ("LKO", "Amausi Airport", "Lucknow"),
            ("JAI", "Jaipur International", "Jaipur"),
            ("VTZ", "Vishakhapatnam International", "Vishakhapatnam"),
            ("IXC", "Chandigarh International", "Chandigarh"),
            ("AGR", "Agrasen International", "Agra"),
            ("VRN", "Varanasi International", "Varanasi"),
            ("IXM", "Madurai Airport", "Madurai"),
            ("CjB", "Coimbatore International", "Coimbatore"),
            ("SXR", "Srinagar International", "Srinagar"),
            ("JDH", "Jammu Airport", "Jammu"),
            ("IDR", "Indore Airport", "Indore"),
            ("RAJ", "Rajkot Airport", "Rajkot"),
            ("BTV", "Belgaum Airport", "Belgaum"),
            ("UDR", "Udaipur Airport", "Udaipur"),
            ("JLR", "Jodhpur Airport", "Jodhpur"),
            ("KJA", "Kunjapuri Air Strip", "Dehradun"),
            ("AGX", "Agatti Airport", "Agatti"),
            ("COI", "Port Blair Airport", "Port Blair"),
            ("TRZ", "Tirupati Airport", "Tirupati"),
            ("ZAY", "Zero Zone Airport", "Aurangabad"),
        ]

        return airportData.map {
            Airport(
                code: $0.code,
                name: $0.name,
                city: $0.city,
                country: "India"
            )
        }
    }

    private func createAircrafts() -> [Aircraft] {
        [
            Aircraft(
                registrationNumber: "VT-IAL",
                type: "Air India Airbus A350-900",
                seatingCapacity: 300,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 10]
            ),
            Aircraft(
                registrationNumber: "VT-ANP",
                type: "Air India Boeing 787-8 Dreamliner",
                seatingCapacity: 256,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 9]
            ),
            Aircraft(
                registrationNumber: "VT-EXC",
                type: "IndiGo Airbus A320neo",
                seatingCapacity: 180,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-IZR",
                type: "IndiGo Airbus A321neo",
                seatingCapacity: 222,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 7]
            ),
            Aircraft(
                registrationNumber: "VT-SCA",
                type: "SpiceJet Boeing 737-800",
                seatingCapacity: 189,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-SPP",
                type: "SpiceJet Bombardier Q400",
                seatingCapacity: 90,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 4]
            ),
            Aircraft(
                registrationNumber: "VT-AXV",
                type: "Vistara Airbus A320neo",
                seatingCapacity: 162,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 5]
            ),
            Aircraft(
                registrationNumber: "VT-TSD",
                type: "Akasa Air Boeing 737 MAX 8",
                seatingCapacity: 189,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-AIR",
                type: "Air India Express Boeing 737-800",
                seatingCapacity: 189,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-IXC",
                type: "Alliance Air ATR 72-600",
                seatingCapacity: 70,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 3]
            ),
        ]
    }

    private func createStaff() -> [Staff] {
        let pilots = [
            "Arvind Sharma", "Vikram Malhotra", "Rohit Kapoor", "Sanjay Desai",
            "Neha Kapoor", "Priyanka Menon", "Ajay Rathore", "Karanveer Singh",
            "Meera Iyer", "Siddharth Bose", "Anjali Nair", "Rahul Mehra",
            "Deepak Chauhan", "Shalini Grover", "Manish Thakur",
        ]

        let coPilots = [
            "Aditya Verma", "Sneha Patel", "Rishi Khanna", "Pooja Chakraborty",
            "Arnav Joshi", "Kavya Reddy", "Devansh Gupta", "Nisha Thomas",
            "Yash Thakur", "Ayesha Khan", "Kunal Mehra", "Tanya Sethi",
        ]

        let cabinCrew = [
            "Amitabh Roy", "Divya Saxena", "Rohan Mehra", "Simran Kaur",
            "Karan Malhotra", "Ananya Rao", "Vikrant Shetty", "Preeti Nair",
            "Arjun Pillai", "Shreya Menon", "Nikhil D'Souza", "Tanya Bose",
            "Sameer Khan", "Riya Chatterjee", "Gautam Iyer", "Pooja Malhotra",
            "Vivek Sharma", "Sakshi Jain", "Rahul Yadav",
        ]

        let emailDomain = [
            "@flyskyindia.com", "@skyindiaairlines.in", "@skyindia.co.in",
            "@flysky.in", "@skyindia.aero",
        ]

        var staff: [Staff] = []
        // Put this in your DemoDataSeeder.swift or a MockData.swift file

        let avatarAssets = (3...18).map { "images-\($0)" }

        // Pilots
        for name in pilots {
            let randomAvatarName = avatarAssets[Int.random(in: 0..<avatarAssets.count)]
            let email =
                name.lowercased()
                .replacingOccurrences(of: " ", with: ".")
                + emailDomain[Int.random(in: 0..<emailDomain.count)]
            staff.append(
                Staff(
                    name: name,
                    designation: .pilot,
                    gender: name.contains("Neha") || name.contains("Priyanka")
                        || name.contains("Meera") || name.contains("Anjali")
                        ? .female : .male,
                    email: email,
                    profileImage: imageData(fromAssetName: randomAvatarName),
                    dob: makeDemoDOB(
                        year: Int.random(in: 1975...1992),
                        month: Int.random(in: 1...12),
                        day: Int.random(in: 1...28)
                    )
                )
            )
        }

        // Co-pilots
        for name in coPilots {
            let randomAvatarName = avatarAssets.randomElement() ?? "default"
            let email =
                name.lowercased()
                .replacingOccurrences(of: " ", with: ".")
                + emailDomain[Int.random(in: 0..<emailDomain.count)]
            staff.append(
                Staff(
                    name: name,
                    designation: .coPilot,
                    gender: name.contains("Sneha") || name.contains("Pooja")
                        || name.contains("Kavya") || name.contains("Nisha")
                        || name.contains("Ayesha") ? .female : .male,
                    email: email,
                    profileImage: imageData(fromAssetName: randomAvatarName),
                    dob: makeDemoDOB(
                        year: Int.random(in: 1988...2000),
                        month: Int.random(in: 1...12),
                        day: Int.random(in: 1...28)
                    )
                )
            )
        }

        // Cabin Crew
        for name in cabinCrew {
            let randomAvatarName = avatarAssets.randomElement() ?? "default"
            let email =
                name.lowercased().replacingOccurrences(of: " ", with: ".")
                + emailDomain[Int.random(in: 0..<emailDomain.count)]
            staff.append(
                Staff(
                    name: name,
                    designation: .cabinCrew,
                    gender: name.contains("Divya") || name.contains("Simran")
                        || name.contains("Ananya") || name.contains("Preeti")
                        || name.contains("Shreya") || name.contains("Tanya")
                        || name.contains("Riya") ? .female : .male,
                    email: email,
                    profileImage: imageData(fromAssetName: randomAvatarName),
                    dob: makeDemoDOB(
                        year: Int.random(in: 1990...2002),
                        month: Int.random(in: 1...12),
                        day: Int.random(in: 1...28)
                    )
                )
            )
        }

        return staff
    }

    private func createRoutes(with airports: [Airport]) -> [Route] {
        var routes: [Route] = []
        let airportCount = airports.count
        let realisticRouteNames = [
            "Delhi–Mumbai Shuttle", "Golden Triangle", "South India Express",
            "North-East Connector", "Western Ghats Flyer", "Kerala–Delhi",
            "Kashmir–Capital", "Eastern Seaboard", "Rajasthan Discovery",
            "Deccan Link", "Bay of Bengal", "Punjab–Maharashtra",
            "Andaman Gateway", "Gujarat–Karnataka", "Uttar Pradesh Express",
        ]

        for i in 0..<15 {
            let route = Route(name: realisticRouteNames[i])

            // Randomly select 2-6 airports
            let nodeCount = Int.random(in: 2...6)
            var selectedIndices = Set<Int>()

            while selectedIndices.count < nodeCount {
                selectedIndices.insert(Int.random(in: 0..<airportCount))
            }

            let selectedAirports = selectedIndices.sorted().map { airports[$0] }

            // Add nodes to route using model function
            for (index, airport) in selectedAirports.enumerated() {
                if index == 0 {
                    // First node: 0 journey time (departure point)
                    route.addNode(
                        airport: airport,
                        journeyTimeMinutes: 0,
                        turnAroundTimeMinutes: 0
                    )
                } else {
                    // Subsequent nodes: journey time 3-10 minutes, turnaround 30 minutes
                    let journeyTime = Int.random(in: 3...10)
                    route.addNode(
                        airport: airport,
                        journeyTimeMinutes: journeyTime,
                        turnAroundTimeMinutes: 30
                    )
                }
            }

            routes.append(route)
        }

        return routes
    }

    private func createTrips(
        routes: [Route],
        aircrafts: [Aircraft],
        staff: [Staff],
        currentDate: Date
    ) -> [Trip] {
        var trips: [Trip] = []
        delayedTripIDs.removeAll()

        let pilots = staff.filter { $0.designation == .pilot }
        let coPilots = staff.filter { $0.designation == .coPilot }
        let crew = staff.filter { $0.designation == .cabinCrew }

        for (routeIndex, route) in routes.enumerated() {
            // Select 2 random trips per route to have delays
            let delayedTripIndices = Set((0..<5).shuffled().prefix(2))

            for tripIndex in 0..<5 {
                let aircraft = aircrafts[Int.random(in: 0..<aircrafts.count)]

                // Assign staff based on aircraft requirements
                var assignedStaff: [Staff] = []

                // Add pilots
                let pilotsRequired = aircraft.minimumStaffRequired[.pilot] ?? 1
                for _ in 0..<pilotsRequired {
                    if let pilot = pilots.randomElement() {
                        assignedStaff.append(pilot)
                    }
                }

                // Add co-pilots
                let coPilotsRequired =
                    aircraft.minimumStaffRequired[.coPilot] ?? 0
                for _ in 0..<coPilotsRequired {
                    if let coPilot = coPilots.randomElement() {
                        assignedStaff.append(coPilot)
                    }
                }

                // Add crew
                let crewRequired =
                    aircraft.minimumStaffRequired[.cabinCrew] ?? 1
                for _ in 0..<crewRequired {
                    if let crewMember = crew.randomElement() {
                        assignedStaff.append(crewMember)
                    }
                }

                // Schedule trip
                let scheduledTime: Date
                if tripIndex < 3 {
                    // First 3 trips: 1, 2, 3 minutes from now
                    scheduledTime = currentDate.addingTimeInterval(
                        TimeInterval((tripIndex + 1) * 60)
                    )
                } else {
                    // Other 2 trips: random future time (days from now)
                    let daysInFuture = Int.random(in: 4...30)
                    scheduledTime = currentDate.addingTimeInterval(
                        TimeInterval(daysInFuture * 86400)
                    )
                }

                let trip = Trip(
                    staff: assignedStaff,
                    aircraft: aircraft,
                    nodeStatuses: [],
                    route: route,
                    scheduledDepartureTime: scheduledTime,
                    flightNumber:
                        "FL-\(seedCount)-\(routeIndex + 1)-\(tripIndex + 1)",
                    isCancelled: false
                )

                // Mark 2 random trips per route to have delays (5-10 minutes)
                if delayedTripIndices.contains(tripIndex) {
                    delayedTripIDs.insert(trip.id)
                }

                assignedStaff.forEach { $0.trips.append(trip) }
                aircraft.trips.append(trip)

                trips.append(trip)
            }
        }

        return trips
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
                        let departureTime = currentTime.addingTimeInterval(
                            30 * 60
                        )
                        trip.scheduleCurrentAirportDeparture(
                            departureTime: departureTime
                        )
                    }
                }
            } else if lastNode.actualDepartureTime == nil {
                // Check if we need to schedule departure
                // Departure should happen after arrival + turnaround time
                if let arrivalTime = lastNode.actualArrivalTime {
                    let plannedDepartureTime = arrivalTime.addingTimeInterval(
                        30 * 60
                    )

                    if currentTime >= plannedDepartureTime {
                        // Check if this is not the last airport
                        if trip.currentAirportSequence < trip.route.nodes.count
                        {
                            trip.scheduleCurrentAirportDeparture(
                                departureTime: currentTime
                            )
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

    private func printSeedingData(
        airports: [Airport],
        aircrafts: [Aircraft],
        staff: [Staff],
        routes: [Route],
        trips: [Trip]
    ) {
        print(
            "\n========== FLIGHT MANAGEMENT SYSTEM - DEMO DATA SEEDED =========="
        )
        print("Seed Count: \(seedCount)")

        print("\n📍 AIRPORTS SEEDED: \(airports.count)")
        for airport in airports {
            print("  ✈️  \(airport.code) - \(airport.name), \(airport.city)")
        }

        print("\n✈️  AIRCRAFTS SEEDED: \(aircrafts.count)")
        for aircraft in aircrafts {
            print(
                "  🛫 \(aircraft.registrationNumber) - \(aircraft.type) (Capacity: \(aircraft.seatingCapacity))"
            )
        }

        print("\n👥 STAFF SEEDED: \(staff.count)")
        let pilots = staff.filter { $0.designation == .pilot }.count
        let coPilots = staff.filter { $0.designation == .coPilot }.count
        let crew = staff.filter { $0.designation == .cabinCrew }.count
        print("  👨‍✈️ Pilots: \(pilots)")
        print("  👨‍✈️ Co-pilots: \(coPilots)")
        print("  👨‍💼 Cabin Crew: \(crew)")

        print("\n🛫 ROUTES SEEDED: \(routes.count)")
        for route in routes {
            print("  🗺️  \(route.name) - \(route.nodes.count) airports")
        }

        print("\n✈️ TRIPS SEEDED: \(trips.count)")
        for trip in trips {
            let isDelayed = delayedTripIDs.contains(trip.id)
            let delayInfo = isDelayed ? " [DELAYED: 5-15 mins]" : ""
            print(
                "  🛫 \(trip.flightNumber) - Route: \(trip.route.name)\(delayInfo)"
            )
        }

        print(
            "===================================================================\n"
        )
    }

    private func printNewTripsSeeded(trips: [Trip]) {
        print(
            "\n========== NEW TRIPS ADDED - SEED COUNT: \(seedCount) =========="
        )
        print("Total Trips Added: \(trips.count)")

        for trip in trips {
            let isDelayed = delayedTripIDs.contains(trip.id)
            let delayInfo = isDelayed ? " [DELAYED: 5-15 mins]" : ""
            print(
                "  🛫 \(trip.flightNumber) - Route: \(trip.route.name)\(delayInfo)"
            )
        }

        print(
            "=================================================================\n"
        )
    }

    private func clearAllData(in context: ModelContext) throws {
        try context.delete(model: Trip.self)
        try context.delete(model: Staff.self)
        try context.delete(model: Aircraft.self)
        try context.delete(model: Route.self)
        try context.delete(model: Airport.self)
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
