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

        await forceReseed(in: context)
    }

    func forceReseed(in context: ModelContext) async {
        seedCount += 1
        let hasData = hasExistingData(in: context)

        if hasData {
            do {
                // Delete in dependency order so relationships are cleared without breaking the context
                let tripDescriptor = FetchDescriptor<Trip>()
                let tripsToDelete = try context.fetch(tripDescriptor)
                for trip in tripsToDelete {
                    context.delete(trip)
                }
                try context.save()

                let staffDescriptor = FetchDescriptor<Staff>()
                let aircraftDescriptor = FetchDescriptor<Aircraft>()
                let routeDescriptor = FetchDescriptor<Route>()
                let airportDescriptor = FetchDescriptor<Airport>()

                for staff in try context.fetch(staffDescriptor) { context.delete(staff) }
                for aircraft in try context.fetch(aircraftDescriptor) { context.delete(aircraft) }
                for route in try context.fetch(routeDescriptor) { context.delete(route) }
                for airport in try context.fetch(airportDescriptor) { context.delete(airport) }

                try context.save()
                isSeeded = false
                print("____________deleted previous data_________________")
            } catch {
                print("ERROR: Cannot reset demo data: \(error)")
                return
            }
        }

        // Create fresh data
        let airports = createIndianAirports()
        let aircrafts = createAircrafts()
        let staff = await createStaff(batchIndex: 0)
        let routes = createRoutes(with: airports)

        for airport in airports { context.insert(airport) }
        for aircraft in aircrafts { context.insert(aircraft) }
        for staffMember in staff { context.insert(staffMember) }
        for route in routes { context.insert(route) }
        try? context.save()

        let trips = createTrips(
            routes: routes,
            aircrafts: aircrafts,
            staff: staff,
            currentDate: Date()
        )
        for trip in trips {
            context.insert(trip)
            for s in trip.staffs { s.trips.append(trip) }
            trip.aircraft.trips.append(trip)
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
        self.modelContext = context

        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true)
        { [weak self] _ in
            self?.simulateFlightProgression(in: context)
        }

        // Every 10 minutes insert more data instead of deleting
        reseedTimer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true)
        { [weak self] _ in
            Task {
                await self?.insertMoreData(in: context)
            }
        }
    }

    func stopAutoUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        reseedTimer?.invalidate()
        reseedTimer = nil
        
        modelContext = nil
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

    /// Staff per batch: 100 (34 pilot, 33 co-pilot, 33 cabin crew). Max 3 batches.
    /// Uses real Indian names and gender-matched stock images (e.g. image1-female, image1-male in Assets).
    private func createStaff(batchIndex: Int) async -> [Staff] {
        let emailDomain = [
            "@flyskyindia.com", "@skyindiaairlines.in", "@skyindia.co.in",
            "@flysky.in", "@skyindia.aero",
        ]
        let pilotCount = 34
        let coPilotCount = 33
        let crewCount = 33

        var staff: [Staff] = []
        var nameOffset = batchIndex * 100
        let assetName = (1...17).map { "images-\($0)" }

        for i in 0..<pilotCount {
            let (name, gender) = Self.indianNameAndGender(at: nameOffset + i, role: .pilot)
            let s = await makeStaff(name: name, gender: gender, designation: .pilot, yearRange: 1975...1992, emailDomain: emailDomain, assetName: assetName.randomElement() ?? "default")
            staff.append(s)
        }
        nameOffset += pilotCount
        for i in 0..<coPilotCount {
            let (name, gender) = Self.indianNameAndGender(at: nameOffset + i, role: .coPilot)
            let s = await makeStaff(name: name, gender: gender, designation: .coPilot, yearRange: 1988...2000, emailDomain: emailDomain, assetName: assetName.randomElement() ?? "default")
            staff.append(s)
        }
        nameOffset += crewCount
        for i in 0..<crewCount {
            let (name, gender) = Self.indianNameAndGender(at: nameOffset + i, role: .cabinCrew)
            let s = await makeStaff(name: name, gender: gender, designation: .cabinCrew, yearRange: 1990...2002, emailDomain: emailDomain, assetName: assetName.randomElement() ?? "default")
            staff.append(s)
        }

        return staff
    }

    private func makeStaff(name: String, gender: Gender, designation: StaffRole, yearRange: ClosedRange<Int>, emailDomain: [String], assetName: String) async -> Staff {
        let email = name.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            + emailDomain[Int.random(in: 0..<emailDomain.count)]
        let imgData = imageData(fromAssetName: assetName)
        let profileBgColor: ColorData
        if let data = imgData, let img = UIImage(data: data),
           let dominantColor = await dominantBackgroundColor(from: img) {
            profileBgColor = ColorData(uiColor: dominantColor)
        } else {
            profileBgColor = ColorData(Color.gray)
        }
        return Staff(
            name: name,
            designation: designation,
            gender: gender,
            email: email,
            profileImage: imgData,
            profileBgColor: profileBgColor,
            dob: makeDemoDOB(
                year: Int.random(in: yearRange),
                month: Int.random(in: 1...12),
                day: Int.random(in: 1...28)
            )
        )
    }

    /// Returns (name, gender) from pool of 100 real Indian names per gender. Role influences gender mix.
    private static func indianNameAndGender(at index: Int, role: StaffRole) -> (String, Gender) {
        let maleIndex = index % indianMaleNames.count
        let femaleIndex = index % indianFemaleNames.count
        let useFemale: Bool
        switch role {
        case .pilot: useFemale = index % 5 == 0
        case .coPilot: useFemale = index % 4 == 0
        case .cabinCrew: useFemale = index % 2 == 0
        }
        if useFemale {
            return (indianFemaleNames[femaleIndex], .female)
        } else {
            return (indianMaleNames[maleIndex], .male)
        }
    }

    private static let indianMaleNames: [String] = [
        "Arvind Sharma", "Vikram Malhotra", "Rohit Kapoor", "Sanjay Desai", "Ajay Rathore",
        "Karanveer Singh", "Siddharth Bose", "Rahul Mehra", "Deepak Chauhan", "Manish Thakur",
        "Aditya Verma", "Rishi Khanna", "Arnav Joshi", "Devansh Gupta", "Yash Thakur",
        "Kunal Mehra", "Amitabh Roy", "Rohan Mehra", "Karan Malhotra", "Vikrant Shetty",
        "Arjun Pillai", "Nikhil D'Souza", "Sameer Khan", "Gautam Iyer", "Vivek Sharma",
        "Rajesh Kumar", "Suresh Nair", "Mahesh Iyer", "Ramesh Patel", "Dinesh Reddy",
        "Amit Singh", "Sunil Deshpande", "Anil Kulkarni", "Sandeep Joshi", "Pradeep Nair",
        "Varun Menon", "Akash Pillai", "Karthik Rao", "Senthil Murugan", "Venkat Krishnan",
        "Ravi Shankar", "Kiran Kumar", "Arun Prakash", "Mohan Das", "Gopal Sharma",
        "Venkatesh Iyengar", "Srinivas Reddy", "Raghav Bhat", "Adarsh Verma", "Vivaan Kapoor",
        "Aryan Malhotra", "Reyansh Singh", "Atharv Joshi", "Advik Nair", "Krish Mehta",
        "Ishan Patel", "Shaurya Rao", "Vihaan Gupta", "Reyansh Sharma", "Aarav Desai",
        "Kabir Khanna", "Arjun Sethi", "Viraj Bose", "Rohan Chatterjee", "Ayaan Reddy",
        "Ritvik Iyer", "Ansh Patel", "Aarav Nair", "Vedant Kumar", "Rishabh Joshi",
        "Kiaan Malhotra", "Aarav Singh", "Arnav Gupta", "Aarav Rao", "Vihaan Mehta",
        "Reyansh Patel", "Aryan Nair", "Aditya Joshi", "Arjun Reddy", "Vivaan Iyer",
        "Rohan Sharma", "Ayaan Desai", "Kabir Khanna", "Ritvik Bose", "Ansh Sethi",
        "Vedant Chatterjee", "Rishabh Kumar", "Kiaan Patel", "Ishan Reddy", "Shaurya Gupta",
        "Viraj Mehta", "Atharv Nair", "Advik Joshi", "Krish Malhotra", "Raghav Singh",
    ]

    private static let indianFemaleNames: [String] = [
        "Neha Kapoor", "Priyanka Menon", "Meera Iyer", "Anjali Nair", "Shalini Grover",
        "Sneha Patel", "Pooja Chakraborty", "Kavya Reddy", "Nisha Thomas", "Ayesha Khan",
        "Tanya Sethi", "Divya Saxena", "Simran Kaur", "Ananya Rao", "Preeti Nair",
        "Shreya Menon", "Tanya Bose", "Riya Chatterjee", "Sakshi Jain", "Pooja Malhotra",
        "Kavita Sharma", "Sunita Desai", "Rekha Nair", "Padmini Iyer", "Lakshmi Reddy",
        "Sita Menon", "Gita Patel", "Rita Kumar", "Deepa Joshi", "Reema Nair",
        "Seema Rao", "Priya Malhotra", "Diya Singh", "Kiara Verma", "Anaya Khanna",
        "Aadhya Bose", "Ishita Sethi", "Myra Chatterjee", "Shanaya Gupta", "Saanvi Rao",
        "Anika Mehta", "Aarya Joshi", "Navya Reddy", "Kavya Nair", "Aaradhya Singh",
        "Ira Patel", "Riya Malhotra", "Anvi Iyer", "Pari Desai", "Diya Sharma",
        "Ishita Nair", "Myra Joshi", "Shanaya Reddy", "Saanvi Gupta", "Anika Rao",
        "Aarya Mehta", "Navya Singh", "Aaradhya Patel", "Ira Malhotra", "Riya Iyer",
        "Anvi Desai", "Pari Sharma", "Kavya Nair", "Neha Reddy", "Priyanka Gupta",
        "Meera Rao", "Anjali Mehta", "Shalini Singh", "Sneha Patel", "Pooja Joshi",
        "Kavya Reddy", "Nisha Malhotra", "Ayesha Iyer", "Tanya Desai", "Divya Sharma",
        "Simran Nair", "Ananya Reddy", "Preeti Gupta", "Shreya Rao", "Riya Mehta",
        "Sakshi Singh", "Kavita Joshi", "Sunita Malhotra", "Rekha Iyer", "Padmini Desai",
        "Lakshmi Sharma", "Sita Nair", "Gita Reddy", "Rita Gupta", "Deepa Rao",
        "Reema Mehta", "Seema Singh", "Priya Joshi", "Diya Malhotra", "Kiara Iyer",
        "Anaya Desai", "Aadhya Sharma", "Ishita Nair", "Myra Reddy", "Shanaya Gupta",
    ]

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
                    route.addNode(airport: airport, journeyTimeMinutes: 0, turnAroundTimeMinutes: 0)
                } else {
                    // Subsequent nodes: journey time 3-10 minutes, turnaround 30 minutes
                    let journeyTime = Int.random(in: 3...5)
                    route.addNode(airport: airport, journeyTimeMinutes: journeyTime, turnAroundTimeMinutes: 30)
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
            let delayedTripIndices = Set((0..<5).shuffled().prefix(2))

            for tripIndex in 0..<10 {
                let scheduledTime: Date
                if tripIndex < 3 {
                    scheduledTime = currentDate.addingTimeInterval(
                        TimeInterval((tripIndex + 1) * 60)
                    )
                } else {
                    let daysInFuture = Int.random(in: 4...30)
                    scheduledTime = currentDate.addingTimeInterval(
                        TimeInterval(daysInFuture * 86400)
                    )
                }

                let endTime = scheduledTime.addingTimeInterval(
                    TimeInterval(route.totalPlannedDurationMinutes * 60)
                )

                // Use model availability: staff available in window
                let availablePilots = pilots.filter { $0.isAvailable(from: scheduledTime, to: endTime) }
                let availableCoPilots = coPilots.filter { $0.isAvailable(from: scheduledTime, to: endTime) }
                let availableCrew = crew.filter { $0.isAvailable(from: scheduledTime, to: endTime) }
                let availableStaffCounts: [StaffRole: Int] = [
                    .pilot: availablePilots.count,
                    .coPilot: availableCoPilots.count,
                    .cabinCrew: availableCrew.count,
                ]

                // Use model availability: aircraft available and staff counts sufficient
                let availableAircraft = aircrafts.filter { aircraft in
                    aircraft.isAvailable(
                        from: scheduledTime,
                        to: endTime,
                        availableStaff: availableStaffCounts
                    )
                }

                guard let aircraft = availableAircraft.randomElement() else { continue }

                let pilotsRequired = aircraft.minimumStaffRequired[.pilot] ?? 1
                let coPilotsRequired = aircraft.minimumStaffRequired[.coPilot] ?? 0
                let crewRequired = aircraft.minimumStaffRequired[.cabinCrew] ?? 1

                var assignedStaff: [Staff] = []
                assignedStaff.append(contentsOf: Array(availablePilots.shuffled().prefix(pilotsRequired)))
                assignedStaff.append(contentsOf: Array(availableCoPilots.shuffled().prefix(coPilotsRequired)))
                assignedStaff.append(contentsOf: Array(availableCrew.shuffled().prefix(crewRequired)))

                let requiredTotal = pilotsRequired + coPilotsRequired + crewRequired
                if assignedStaff.count < requiredTotal { continue }

                let trip = Trip(
                    staff: assignedStaff,
                    aircraft: aircraft,
                    nodeStatuses: [],
                    route: route,
                    scheduledDepartureTime: scheduledTime,
                    flightNumber: "FL-\(seedCount)-\(routeIndex + 1)-\(tripIndex + 1)",
                    isCancelled: false
                )

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

    // MARK: - Insert more data (no delete)
    private func insertMoreData(in context: ModelContext) async {
        do {
            let staffDescriptor = FetchDescriptor<Staff>()
            let allStaff = try context.fetch(staffDescriptor)
            let batchCount = allStaff.count / 100
            if batchCount >= 3 { return }

            let newStaff = await createStaff(batchIndex: batchCount)
            for s in newStaff { context.insert(s) }
            try context.save()

            let routeDescriptor = FetchDescriptor<Route>()
            let aircraftDescriptor = FetchDescriptor<Aircraft>()
            let routes = try context.fetch(routeDescriptor)
            let aircrafts = try context.fetch(aircraftDescriptor)
            let combinedStaff = allStaff + newStaff

            let newTrips = createTrips(
                routes: routes,
                aircrafts: aircrafts,
                staff: combinedStaff,
                currentDate: Date()
            )
            for trip in newTrips {
                context.insert(trip)
                for s in trip.staffs { s.trips.append(trip) }
                trip.aircraft.trips.append(trip)
            }
            try context.save()
            printNewTripsSeeded(trips: newTrips)
        } catch {
            print("Error inserting more data: \(error)")
        }
    }

    // MARK: - Flight Simulator (uses only Trip arrival/departure APIs)
    private func simulateFlightProgression(in context: ModelContext) {
        let currentTime = Date()

        do {
            let descriptor = FetchDescriptor<Trip>()
            let allTrips = try context.fetch(descriptor)

            for trip in allTrips {
                if !trip.isCancelled && !trip.isCompleted && trip.nodeStatuses.isEmpty {
                    if trip.scheduledDepartureTime <= currentTime {
                        trip.startTrip(departureTime: currentTime)
                    }
                }

                if !trip.isCancelled && !trip.isCompleted && !trip.nodeStatuses.isEmpty {
                    progressTrip(trip, currentTime: currentTime)
                }
            }

            try context.save()
        } catch {
            print("Error during flight simulation: \(error)")
        }
    }

    /// Progress trip using only Trip model APIs: scheduleCurrentAirportArrival, scheduleCurrentAirportDeparture.
    private func progressTrip(_ trip: Trip, currentTime: Date) {
        guard !trip.isCancelled && !trip.isCompleted else { return }

        let lastNodeStatus = trip.nodeStatuses.last
        guard let lastNode = lastNodeStatus else { return }

        if lastNode.actualArrivalTime == nil {
            var plannedArrivalTime = trip.scheduledDepartureTime
                .addingTimeInterval(
                    TimeInterval(lastNode.routeNode.plannedArrivalOffsetMinutes * 60)
                )
            if delayedTripIDs.contains(trip.id) {
                plannedArrivalTime = plannedArrivalTime.addingTimeInterval(
                    TimeInterval(Int.random(in: 5...10) * 60)
                )
            }

            if currentTime >= plannedArrivalTime {
                trip.scheduleCurrentAirportArrival(arrivalTime: currentTime)
                if trip.currentAirportSequence < trip.route.nodes.count {
                    let departureTime = currentTime.addingTimeInterval(30 * 60)
                    trip.scheduleCurrentAirportDeparture(departureTime: departureTime)
                }
            }
        } else if lastNode.actualDepartureTime == nil {
            if let arrivalTime = lastNode.actualArrivalTime {
                let plannedDepartureTime = arrivalTime.addingTimeInterval(30 * 60)
                if currentTime >= plannedDepartureTime
                    && trip.currentAirportSequence < trip.route.nodes.count
                {
                    trip.scheduleCurrentAirportDeparture(departureTime: currentTime)
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
