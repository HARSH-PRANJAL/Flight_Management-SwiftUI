import Foundation
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
            // Just create and add new trips to existing data
            do {
                let descriptor = FetchDescriptor<Route>()
                let routes = try context.fetch(descriptor)
                
                let aircraftDescriptor = FetchDescriptor<Aircraft>()
                let aircrafts = try context.fetch(aircraftDescriptor)
                
                let staffDescriptor = FetchDescriptor<Staff>()
                let staffs = try context.fetch(staffDescriptor)
                
                if !routes.isEmpty && !aircrafts.isEmpty && !staffs.isEmpty {
                    let newTrips = createTrips(routes: routes, aircrafts: aircrafts, staff: staffs, currentDate: Date())
                    for trip in newTrips {
                        context.insert(trip)
                    }
                    try context.save()
                    printNewTripsSeeded(trips: newTrips)
                    return
                }
            } catch {
                print("Error loading existing data: \(error)")
            }
        }
        
        // Create fresh data if nothing exists
        let airports = createIndianAirports()
        let aircrafts = createAircrafts()
        let staff = createStaff()
        let routes = createRoutes(with: airports)
        let trips = createTrips(routes: routes, aircrafts: aircrafts, staff: staff, currentDate: Date())
        
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
            printSeedingData(airports: airports, aircrafts: aircrafts, staff: staff, routes: routes, trips: trips)
        } catch {
            print("Failed to seed demo data: \(error)")
        }
    }
    
    func startAutoUpdates(in context: ModelContext) {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.simulateFlightProgression(in: context)
        }
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
        
        return airportData.map { Airport(code: $0.code, name: $0.name, city: $0.city, country: "India") }
    }
    
    private func createAircrafts() -> [Aircraft] {
        let aircrafts: [Aircraft] = [
            Aircraft(registrationNumber: "VT-ANA", type: "Boeing 777", seatingCapacity: 350, minimumStaffRequired: [.pilot: 1, .coPilot: 0, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANB", type: "Boeing 787", seatingCapacity: 280, minimumStaffRequired: [.pilot: 1, .coPilot: 0, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANC", type: "Airbus A320", seatingCapacity: 180, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-AND", type: "Airbus A330", seatingCapacity: 300, minimumStaffRequired: [.pilot: 1, .coPilot: 0, .cabinCrew: 2]),
            Aircraft(registrationNumber: "VT-ANE", type: "Embraer E190", seatingCapacity: 200, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANF", type: "Boeing 737", seatingCapacity: 160, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANG", type: "Airbus A321", seatingCapacity: 190, minimumStaffRequired: [.pilot: 1, .coPilot: 0, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANH", type: "Boeing 767", seatingCapacity: 270, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 2]),
            Aircraft(registrationNumber: "VT-ANI", type: "Bombardier Q400", seatingCapacity: 90, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANJ", type: "ATR 72", seatingCapacity: 70, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANK", type: "Boeing 777", seatingCapacity: 350, minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 2]),
            Aircraft(registrationNumber: "VT-ANL", type: "Airbus A380", seatingCapacity: 500, minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 3]),
            Aircraft(registrationNumber: "VT-ANM", type: "Boeing 787", seatingCapacity: 280, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANN", type: "Airbus A350", seatingCapacity: 325, minimumStaffRequired: [.pilot: 1, .coPilot: 0, .cabinCrew: 2]),
            Aircraft(registrationNumber: "VT-ANO", type: "Boeing 737", seatingCapacity: 160, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANP", type: "Embraer E195", seatingCapacity: 220, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANQ", type: "Airbus A320", seatingCapacity: 180, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANR", type: "Boeing 767", seatingCapacity: 270, minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 2]),
            Aircraft(registrationNumber: "VT-ANS", type: "Airbus A321", seatingCapacity: 190, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 1]),
            Aircraft(registrationNumber: "VT-ANT", type: "Boeing 777", seatingCapacity: 350, minimumStaffRequired: [.pilot: 1, .coPilot: 1, .cabinCrew: 2]),
        ]
        return aircrafts
    }
    
    private func createStaff() -> [Staff] {
        let indianPilotNames = [
            "Captain Rajesh Kumar", "Captain Pradeep Singh", "Captain Virender Sehwag",
            "Captain Arun Sharma", "Captain Nikhat Khan", "Captain Deepak Nair",
            "Captain Manish Patel", "Captain Suresh Reddy", "Captain Harinder Sidhu",
            "Captain Rajiv Mishra", "Captain Ashok Kumar", "Captain Sanjay Verma",
            "Captain Ramesh Gupta", "Captain Vikram Singh", "Captain Anand Rao",
            "Captain Ravi Tomar", "Captain Nitin Joshi", "Captain Karthik Subramanian",
            "Captain Mohan Lal", "Captain Sandeep Singh", "Captain Ajay Kumar",
            "Captain Bhaskar Roy", "Captain Chandra Mohan", "Captain Dhanraj Pillai",
            "Captain Eknath Solkar", "Captain Fawad Ali", "Captain Govind Sharma",
            "Captain Hardik Pandya", "Captain Ishant Sharma", "Captain Jasprit Bumrah",
        ]
        
        let indianCoPilotNames = [
            "First Officer Priya Sharma", "First Officer Simran Kaur", "First Officer Aisha Khan",
            "First Officer Neha Gupta", "First Officer Zara Patel", "First Officer Sophia Singh",
            "First Officer Ananya Desai", "First Officer Diya Verma", "First Officer Erica Nair",
            "First Officer Fiza Khan", "First Officer Geetika Roy", "First Officer Honey Sharma",
            "First Officer Isha Malhotra", "First Officer Jasmine Reddy", "First Officer Kalpana Bhat",
            "First Officer Lakshmi Murthy", "First Officer Megha Chopra", "First Officer Navya Iyer",
            "First Officer Olivia Fernandes", "First Officer Priya Menon", "First Officer Quinzia D'Souza",
            "First Officer Ritika Singh", "First Officer Shruti Bhat", "First Officer Tanya Puri",
            "First Officer Uma Shetty", "First Officer Vaishali Nair", "First Officer Wilma Fernandes",
            "First Officer Xenia Dasgupta", "First Officer Yasmin Khan", "First Officer Zonia Rao",
        ]
        
        let indianCrewNames = [
            "Cabin Crew Amit Patel", "Cabin Crew Bhavna Singh", "Cabin Crew Chirag Verma",
            "Cabin Crew Divya Sharma", "Cabin Crew Emran Khan", "Cabin Crew Farhan Ali",
            "Cabin Crew Gaurav Desai", "Cabin Crew Heenal Gupta", "Cabin Crew Imran Siddiqui",
            "Cabin Crew Jitendra Rao", "Cabin Crew Kriti Nair", "Cabin Crew Laxman Pillai",
            "Cabin Crew Manoj Kumar", "Cabin Crew Nikhil Reddy", "Cabin Crew Omkar Singh",
            "Cabin Crew Param Bhat", "Cabin Crew Quentin D'Souza", "Cabin Crew Rahul Iyer",
            "Cabin Crew Sameer Khan", "Cabin Crew Tushar Malhotra", "Cabin Crew Uday Prabhu",
            "Cabin Crew Varun Chopra", "Cabin Crew Waqar Ahmed", "Cabin Crew Xander Fernandes",
            "Cabin Crew Yogesh Sharma", "Cabin Crew Zain Mirza", "Cabin Crew Aditya Banerjee",
            "Cabin Crew Babul Roy", "Cabin Crew Cavin Menon", "Cabin Crew Dheeraj Shetty",
        ]
        
        var staffList: [Staff] = []
        
        // Create pilots
        for name in indianPilotNames {
            let dob = makeDemoDOB(year: Int.random(in: 2000...2016), month: Int.random(in: 1...12), day: Int.random(in: 1...28))
            let email = name.lowercased().replacingOccurrences(of: " ", with: ".") + "@airlineindia.com"
            staffList.append(Staff(
                name: name,
                designation: .pilot,
                gender: name.contains("Captain") ? .male : .female,
                email: email,
                dob: dob
            ))
        }
        
        // Create co-pilots
        for name in indianCoPilotNames {
            let dob = makeDemoDOB(year: Int.random(in: 1990...2010), month: Int.random(in: 1...12), day: Int.random(in: 1...28))
            let email = name.lowercased().replacingOccurrences(of: " ", with: ".") + "@airlineindia.com"
            staffList.append(Staff(
                name: name,
                designation: .coPilot,
                gender: name.contains("Officer") && name.containsAny("Priya", "Simran", "Aisha", "Neha", "Zara") ? .female : .male,
                email: email,
                dob: dob
            ))
        }
        
        // Create crew members
        for name in indianCrewNames {
            let dob = makeDemoDOB(year: Int.random(in: 1995...2012), month: Int.random(in: 1...12), day: Int.random(in: 1...28))
            let email = name.lowercased().replacingOccurrences(of: " ", with: ".") + "@airlineindia.com"
            staffList.append(Staff(
                name: name,
                designation: .cabinCrew,
                gender: .random() ? .male : .female,
                email: email,
                dob: dob
            ))
        }
        
        return staffList
    }
    
    private func createRoutes(with airports: [Airport]) -> [Route] {
        var routes: [Route] = []
        let airportCount = airports.count
        
        for i in 0..<15 {
            let route = Route(name: "Route-\(i + 1)")
            
            // Randomly select 2-6 airports
            let nodeCount = Int.random(in: 2...6)
            var selectedIndices = Set<Int>()
            
            while selectedIndices.count < nodeCount {
                selectedIndices.insert(Int.random(in: 0..<airportCount))
            }
            
            let selectedAirports = selectedIndices.sorted().map { airports[$0] }
            
            // Add nodes to route
            for (index, airport) in selectedAirports.enumerated() {
                if index == 0 {
                    // First node always has 0 offset
                    let node = RouteNode(plannedArrivalOffsetMinutes: 0, airport: airport)
                    route.nodes.append(node)
                } else {
                    // Add journey time between 3-10 minutes
                    let journeyTime = Int.random(in: 3...10)
                    let previousOffset = route.nodes.last?.plannedArrivalOffsetMinutes ?? 0
                    let newOffset = previousOffset + journeyTime
                    let node = RouteNode(plannedArrivalOffsetMinutes: newOffset, airport: airport)
                    route.nodes.append(node)
                }
            }
            
            routes.append(route)
        }
        
        return routes
    }
    
    private func createTrips(routes: [Route], aircrafts: [Aircraft], staff: [Staff], currentDate: Date) -> [Trip] {
        var trips: [Trip] = []
        delayedTripIDs.removeAll()
        
        let pilots = staff.filter { $0.designation == .pilot }
        let coPilots = staff.filter { $0.designation == .coPilot }
        let crew = staff.filter { $0.designation == .cabinCrew }
        
        for (routeIndex, route) in routes.enumerated() {
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
                let coPilotsRequired = aircraft.minimumStaffRequired[.coPilot] ?? 0
                for _ in 0..<coPilotsRequired {
                    if let coPilot = coPilots.randomElement() {
                        assignedStaff.append(coPilot)
                    }
                }
                
                // Add crew
                let crewRequired = aircraft.minimumStaffRequired[.cabinCrew] ?? 1
                for _ in 0..<crewRequired {
                    if let crewMember = crew.randomElement() {
                        assignedStaff.append(crewMember)
                    }
                }
                
                // Schedule trip
                let scheduledTime: Date
                if tripIndex < 3 {
                    // First 3 trips: 1, 2, 3 minutes from now
                    scheduledTime = currentDate.addingTimeInterval(TimeInterval((tripIndex + 1) * 60))
                } else {
                    // Other 2 trips: random future time (days from now)
                    let daysInFuture = Int.random(in: 4...30)
                    scheduledTime = currentDate.addingTimeInterval(TimeInterval(daysInFuture * 86400))
                }
                
                let trip = Trip(
                    staff: assignedStaff,
                    aircraft: aircraft,
                    nodeStatuses: [],
                    route: route,
                    scheduledDepartureTime: scheduledTime,
                    flightNumber: "FL-\(seedCount)-\(routeIndex + 1)-\(tripIndex + 1)",
                    isCancelled: false
                )
                
                // Mark first trip of each route to have delays
                if tripIndex == 0 {
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
                if !trip.isCancelled && !trip.isCompleted && trip.nodeStatuses.isEmpty {
                    if trip.scheduledDepartureTime <= currentTime {
                        trip.startTrip(departureTime: currentTime)
                    }
                }
                
                // Progress ongoing trips
                if !trip.isCancelled && !trip.isCompleted && !trip.nodeStatuses.isEmpty {
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
                var plannedArrivalTime = trip.scheduledDepartureTime.addingTimeInterval(
                    TimeInterval(lastNode.routeNode.plannedArrivalOffsetMinutes * 60)
                )
                
                // Add delay if this trip should have delays
                if delayedTripIDs.contains(trip.id) {
                    let delayMinutes = Int.random(in: 5...15)
                    plannedArrivalTime = plannedArrivalTime.addingTimeInterval(TimeInterval(delayMinutes * 60))
                }
                
                if currentTime >= plannedArrivalTime {
                    trip.scheduleCurrentAirportArrival(arrivalTime: currentTime)
                    
                    // Schedule departure 2 minutes after arrival
                    let departureTime = currentTime.addingTimeInterval(120)
                    
                    // Check if this is not the last airport
                    if trip.currentAirportSequence < trip.route.nodes.count {
                        scheduleNextDeparture(for: trip, departureTime: departureTime)
                    }
                }
            }
        }
    }
    
    private func scheduleNextDeparture(for trip: Trip, departureTime: Date) {
        // This will be scheduled in the next simulator cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            if !trip.isCancelled && !trip.isCompleted {
                trip.scheduleCurrentAirportDeparture(departureTime: departureTime)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func hasExistingData(in context: ModelContext) -> Bool {
        do {
            let airports = try context.fetch(FetchDescriptor<Airport>())
            return !airports.isEmpty
        } catch {
            return false
        }
    }
    
    private func printSeedingData(airports: [Airport], aircrafts: [Aircraft], staff: [Staff], routes: [Route], trips: [Trip]) {
        print("\n========== FLIGHT MANAGEMENT SYSTEM - DEMO DATA SEEDED ==========")
        print("Seed Count: \(seedCount)")
        
        print("\n📍 AIRPORTS SEEDED: \(airports.count)")
        for airport in airports {
            print("  ✈️  \(airport.code) - \(airport.name), \(airport.city)")
        }
        
        print("\n✈️  AIRCRAFTS SEEDED: \(aircrafts.count)")
        for aircraft in aircrafts {
            print("  🛫 \(aircraft.registrationNumber) - \(aircraft.type) (Capacity: \(aircraft.seatingCapacity))")
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
            print("  🛫 \(trip.flightNumber) - Route: \(trip.route.name)\(delayInfo)")
        }
        
        print("===================================================================\n")
    }
    
    private func printNewTripsSeeded(trips: [Trip]) {
        print("\n========== NEW TRIPS ADDED - SEED COUNT: \(seedCount) ==========")
        print("Total Trips Added: \(trips.count)")
        
        for trip in trips {
            let isDelayed = delayedTripIDs.contains(trip.id)
            let delayInfo = isDelayed ? " [DELAYED: 5-15 mins]" : ""
            print("  🛫 \(trip.flightNumber) - Route: \(trip.route.name)\(delayInfo)")
        }
        
        print("=================================================================\n")
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
