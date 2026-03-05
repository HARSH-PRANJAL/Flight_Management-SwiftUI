import Foundation
import Observation
import SwiftData
import SwiftUI

@Observable
final class DemoDataSeeder {
    static let shared = DemoDataSeeder()
    private var isSeeded: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isSeeded")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isSeeded")
        }
    }

    private var updateTimer: Timer?
    private var reseedTimer: Timer?

    private var modelContext: ModelContext?

    private var allTrips: [Trip] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { !$0.isCancelled && !$0.isCompleted }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var allStaff: [Staff] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Staff>(
            predicate: #Predicate { !$0.isMarkedUnavailable }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var pilots: [Staff] {
        return allStaff.filter {
            $0.designation == StaffRole.pilot
        }
    }

    private var coPilots: [Staff] {
        return allStaff.filter {
            $0.designation == StaffRole.coPilot
        }
    }

    private var crew: [Staff] {
        return allStaff.filter {
            $0.designation == StaffRole.cabinCrew
        }
    }

    private var seedCount: Int {
        get {
            UserDefaults.standard.integer(forKey: "flightSeedCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "flightSeedCount")
        }
    }

    // 10 email domains
    let emailDomain = [
        "@aerowingindia.com",
        "@bluejetair.in",
        "@indiflyers.co.in",
        "@airconnectindia.com",
        "@cloudroute.aero",
        "@skylinkaviation.in",
        "@bharatairways.com",
        "@jetstreamindia.in",
        "@horizonfly.co.in",
        "@altitudeair.aero",
    ]

    // 100 male names
    private static let indianMaleNames: [String] = [
        "Arvind Sharma", "Vikram Malhotra", "Rohit Kapoor", "Sanjay Desai",
        "Ajay Rathore",
        "Karanveer Singh", "Siddharth Bose", "Rahul Mehra", "Deepak Chauhan",
        "Manish Thakur",
        "Aditya Verma", "Rishi Khanna", "Arnav Joshi", "Devansh Gupta",
        "Yash Thakur",
        "Kunal Mehra", "Amitabh Roy", "Rohan Mehra", "Karan Malhotra",
        "Vikrant Shetty",
        "Arjun Pillai", "Nikhil D'Souza", "Sameer Khan", "Gautam Iyer",
        "Vivek Sharma",
        "Rajesh Kumar", "Suresh Nair", "Mahesh Iyer", "Ramesh Patel",
        "Dinesh Reddy",
        "Amit Singh", "Sunil Deshpande", "Anil Kulkarni", "Sandeep Joshi",
        "Pradeep Nair",
        "Varun Menon", "Akash Pillai", "Karthik Rao", "Senthil Murugan",
        "Venkat Krishnan",
        "Ravi Shankar", "Kiran Kumar", "Arun Prakash", "Mohan Das",
        "Gopal Sharma",
        "Venkatesh Iyengar", "Srinivas Reddy", "Raghav Bhat", "Adarsh Verma",
        "Vivaan Kapoor",
        "Aryan Malhotra", "Reyansh Singh", "Atharv Joshi", "Advik Nair",
        "Krish Mehta",
        "Ishan Patel", "Shaurya Rao", "Vihaan Gupta", "Aarav Desai",
        "Kabir Khanna",
        "Arjun Sethi", "Viraj Bose", "Rohan Chatterjee", "Ayaan Reddy",
        "Ritvik Iyer",
        "Ansh Patel", "Vedant Kumar", "Rishabh Joshi", "Kiaan Malhotra",
        "Aarav Singh",
        "Arnav Gupta", "Aarav Rao", "Vihaan Mehta", "Reyansh Patel",
        "Aryan Nair",
        "Aditya Joshi", "Arjun Reddy", "Vivaan Iyer", "Rohan Sharma",
        "Ayaan Desai",
        "Ansh Sethi", "Vedant Chatterjee", "Rishabh Kumar", "Kiaan Patel",
        "Ishan Reddy",
        "Shaurya Gupta", "Viraj Mehta", "Atharv Nair", "Advik Joshi",
        "Krish Malhotra",
        "Raghav Singh", "Harshvardhan Rao", "Lakshya Bansal", "Tanishq Arora",
        "Parth Trivedi", "Omkar Sawant", "Tejas Kulkarni", "Naman Agarwal",
        "Dhruv Saxena", "Yuvraj Choudhary",
    ]

    // 100 female names
    private static let indianFemaleNames: [String] = [
        "Neha Kapoor", "Priyanka Menon", "Meera Iyer", "Anjali Nair",
        "Shalini Grover",
        "Sneha Patel", "Pooja Chakraborty", "Kavya Reddy", "Nisha Thomas",
        "Ayesha Khan",
        "Tanya Sethi", "Divya Saxena", "Simran Kaur", "Ananya Rao",
        "Preeti Nair",
        "Shreya Menon", "Tanya Bose", "Riya Chatterjee", "Sakshi Jain",
        "Pooja Malhotra",
        "Kavita Sharma", "Sunita Desai", "Rekha Nair", "Padmini Iyer",
        "Lakshmi Reddy",
        "Sita Menon", "Gita Patel", "Rita Kumar", "Deepa Joshi", "Reema Nair",
        "Seema Rao", "Priya Malhotra", "Diya Singh", "Kiara Verma",
        "Anaya Khanna",
        "Aadhya Bose", "Ishita Sethi", "Myra Chatterjee", "Shanaya Gupta",
        "Saanvi Rao",
        "Anika Mehta", "Aarya Joshi", "Navya Reddy", "Kavya Nambiar",
        "Aaradhya Singh",
        "Ira Patel", "Riya Malhotra", "Anvi Iyer", "Pari Desai", "Diya Sharma",
        "Ishika Nair", "Myra Joshi", "Shanvika Reddy", "Saanvi Gupta",
        "Anika Rao",
        "Aarya Mehta", "Navya Singh", "Aaradhya Patel", "Ira Malhotra",
        "Riya Iyer",
        "Anvi Desai", "Parineeti Sharma", "Neha Reddy", "Priyanka Gupta",
        "Meera Rao",
        "Anjali Mehta", "Shalini Singh", "Snehal Kulkarni", "Pooja Joshi",
        "Kavya Iyer",
        "Nisha Malhotra", "Ayesha Iqbal", "Tanvi Desai", "Divyanshi Sharma",
        "Simran Nair", "Ananya Reddy", "Preeti Gupta", "Shreya Rao",
        "Riya Mehta",
        "Sakshi Singh", "Kavya Joshi", "Sunita Malhotra", "Rekha Iyer",
        "Padmini Desai",
        "Lakshmi Sharma", "Sita Nair", "Gita Reddy", "Ritika Gupta",
        "Deepika Rao",
        "Reema Mehta", "Sejal Singh", "Priya Joshi", "Diya Malhotra",
        "Kiara Iyer",
        "Anaya Desai", "Aadhira Sharma", "Ishani Nair", "Mythili Reddy",
        "Shanaya Bhat", "Vaishnavi Kulkarni",
    ]

    // 80 airports
    private func airportData() -> [Airport] {
        let airportData: [(code: String, name: String, city: String)] = [

            // 🔵 Major Metro / International Hubs
            ("DEL", "Indira Gandhi International Airport", "Delhi"),
            (
                "BOM", "Chhatrapati Shivaji Maharaj International Airport",
                "Mumbai"
            ),
            ("BLR", "Kempegowda International Airport", "Bengaluru"),
            ("HYD", "Rajiv Gandhi International Airport", "Hyderabad"),
            ("MAA", "Chennai International Airport", "Chennai"),
            (
                "CCU", "Netaji Subhas Chandra Bose International Airport",
                "Kolkata"
            ),
            (
                "AMD", "Sardar Vallabhbhai Patel International Airport",
                "Ahmedabad"
            ),
            ("COK", "Cochin International Airport", "Kochi"),
            ("GOI", "Dabolim Airport", "Goa"),
            ("GOX", "Manohar International Airport", "Goa"),
            ("TRV", "Trivandrum International Airport", "Thiruvananthapuram"),
            ("PNQ", "Pune Airport", "Pune"),
            ("LKO", "Chaudhary Charan Singh International Airport", "Lucknow"),
            ("JAI", "Jaipur International Airport", "Jaipur"),
            (
                "GAU", "Lokpriya Gopinath Bordoloi International Airport",
                "Guwahati"
            ),
            ("PAT", "Jay Prakash Narayan International Airport", "Patna"),
            ("BBI", "Biju Patnaik International Airport", "Bhubaneswar"),
            ("ATQ", "Sri Guru Ram Dass Jee International Airport", "Amritsar"),
            ("VNS", "Lal Bahadur Shastri International Airport", "Varanasi"),
            ("IXC", "Chandigarh International Airport", "Chandigarh"),

            // 🟢 Tier-1 / High Traffic Domestic
            ("IDR", "Devi Ahilya Bai Holkar Airport", "Indore"),
            ("NAG", "Dr. Babasaheb Ambedkar International Airport", "Nagpur"),
            ("RPR", "Swami Vivekananda Airport", "Raipur"),
            ("IXR", "Birsa Munda Airport", "Ranchi"),
            ("IXB", "Bagdogra International Airport", "Bagdogra"),
            ("IMF", "Imphal International Airport", "Imphal"),
            ("IXA", "Maharaja Bir Bikram Airport", "Agartala"),
            ("SXR", "Sheikh ul-Alam International Airport", "Srinagar"),
            ("IXJ", "Jammu Airport", "Jammu"),
            ("DED", "Jolly Grant Airport", "Dehradun"),
            ("GAY", "Gaya Airport", "Gaya"),
            ("IXL", "Kushok Bakula Rimpochee Airport", "Leh"),
            ("IXE", "Mangaluru International Airport", "Mangaluru"),
            ("TRZ", "Tiruchirappalli International Airport", "Tiruchirappalli"),
            ("CJB", "Coimbatore International Airport", "Coimbatore"),
            ("IXM", "Madurai Airport", "Madurai"),
            ("VGA", "Vijayawada Airport", "Vijayawada"),
            ("VTZ", "Visakhapatnam International Airport", "Visakhapatnam"),
            ("TIR", "Tirupati Airport", "Tirupati"),
            ("UDR", "Maharana Pratap Airport", "Udaipur"),

            // 🟡 Important Regional Airports
            ("JDH", "Jodhpur Airport", "Jodhpur"),
            ("RAJ", "Rajkot Airport", "Rajkot"),
            ("BHJ", "Bhuj Airport", "Bhuj"),
            ("BDQ", "Vadodara Airport", "Vadodara"),
            ("IXY", "Kandla Airport", "Kandla"),
            ("HBX", "Hubli Airport", "Hubballi"),
            ("IXG", "Belagavi Airport", "Belagavi"),
            ("KLH", "Kolhapur Airport", "Kolhapur"),
            ("ISK", "Ozar Airport", "Nashik"),
            ("AGX", "Agatti Airport", "Agatti"),
            ("IXZ", "Veer Savarkar International Airport", "Port Blair"),
            ("DIB", "Dibrugarh Airport", "Dibrugarh"),
            ("JRH", "Jorhat Airport", "Jorhat"),
            ("IXS", "Silchar Airport", "Silchar"),
            ("AJL", "Lengpui Airport", "Aizawl"),
            ("SHL", "Shillong Airport", "Shillong"),
            ("DMU", "Dimapur Airport", "Dimapur"),
            ("TEZ", "Tezpur Airport", "Tezpur"),
            ("TCR", "Tuticorin Airport", "Thoothukudi"),
            ("CNN", "Kannur International Airport", "Kannur"),

            // 🔴 Growing / UDAN Network Airports
            ("BHU", "Bhavnagar Airport", "Bhavnagar"),
            ("PBD", "Porbandar Airport", "Porbandar"),
            ("JGA", "Jamnagar Airport", "Jamnagar"),
            ("IXU", "Chhatrapati Sambhaji Nagar Airport", "Aurangabad"),
            ("NDC", "Nanded Airport", "Nanded"),
            ("SAG", "Shirdi Airport", "Shirdi"),
            ("GWL", "Rajmata Vijaya Raje Scindia Airport", "Gwalior"),
            ("HJR", "Khajuraho Airport", "Khajuraho"),
            ("IXD", "Prayagraj Airport", "Prayagraj"),
            ("KNU", "Kanpur Airport", "Kanpur"),
            ("PGH", "Pantnagar Airport", "Pantnagar"),
            ("SLV", "Shimla Airport", "Shimla"),
            ("DHM", "Kangra Airport", "Dharamshala"),
            ("KUU", "Kullu–Manali Airport", "Kullu"),
            ("BEP", "Jindal Vijaynagar Airport", "Ballari"),
            ("MYQ", "Mysuru Airport", "Mysuru"),
            ("CDP", "Kadapa Airport", "Kadapa"),
            ("RJA", "Rajahmundry Airport", "Rajahmundry"),
            ("JLR", "Jabalpur Airport", "Jabalpur"),
            ("STV", "Surat Airport", "Surat"),
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

    // 20 aircrafts
    private func aircraftData() -> [Aircraft] {
        [
            Aircraft(
                registrationNumber: "VT-IAL",
                type: "Air India Airbus A350-900",
                seatingCapacity: 316,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 14]
            ),
            Aircraft(
                registrationNumber: "VT-ANP",
                type: "Air India Boeing 787-8 Dreamliner",
                seatingCapacity: 256,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 12]
            ),
            Aircraft(
                registrationNumber: "VT-ALX",
                type: "Air India Boeing 777-300ER",
                seatingCapacity: 370,
                minimumStaffRequired: [.pilot: 2, .coPilot: 2, .cabinCrew: 16]
            ),
            Aircraft(
                registrationNumber: "VT-VLO",
                type: "Vistara Boeing 787-9 Dreamliner",
                seatingCapacity: 299,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 13]
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
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 8]
            ),
            Aircraft(
                registrationNumber: "VT-SCA",
                type: "SpiceJet Boeing 737-800",
                seatingCapacity: 189,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-TSD",
                type: "Akasa Air Boeing 737 MAX 8",
                seatingCapacity: 197,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-AIR",
                type: "Air India Express Boeing 737-8",
                seatingCapacity: 176,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
            Aircraft(
                registrationNumber: "VT-AXV",
                type: "Vistara Airbus A320neo",
                seatingCapacity: 162,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 5]
            ),
            Aircraft(
                registrationNumber: "VT-IND",
                type: "IndiGo Airbus A321XLR",
                seatingCapacity: 220,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 8]
            ),
            Aircraft(
                registrationNumber: "VT-JET",
                type: "SpiceJet Boeing 737 MAX 9",
                seatingCapacity: 220,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 8]
            ),
            Aircraft(
                registrationNumber: "VT-SPP",
                type: "SpiceJet Bombardier Q400",
                seatingCapacity: 90,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 4]
            ),
            Aircraft(
                registrationNumber: "VT-IXC",
                type: "Alliance Air ATR 72-600",
                seatingCapacity: 70,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 3]
            ),
            Aircraft(
                registrationNumber: "VT-ATR",
                type: "IndiGo ATR 72-600",
                seatingCapacity: 78,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 3]
            ),
            Aircraft(
                registrationNumber: "VT-RGN",
                type: "Alliance Air Dornier 228",
                seatingCapacity: 19,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 1]
            ),
            Aircraft(
                registrationNumber: "VT-AEX",
                type: "Air India Airbus A321neo",
                seatingCapacity: 200,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 7]
            ),
            Aircraft(
                registrationNumber: "VT-BIG",
                type: "Air India Boeing 777-200LR",
                seatingCapacity: 342,
                minimumStaffRequired: [.pilot: 2, .coPilot: 2, .cabinCrew: 15]
            ),
            Aircraft(
                registrationNumber: "VT-WBD",
                type: "Air India Airbus A330-300",
                seatingCapacity: 277,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 12]
            ),
            Aircraft(
                registrationNumber: "VT-LUX",
                type: "Vistara Airbus A321neo",
                seatingCapacity: 188,
                minimumStaffRequired: [.pilot: 2, .coPilot: 0, .cabinCrew: 6]
            ),
        ]
    }
}

// MARK: API & Simulator
extension DemoDataSeeder {
    // MARK: - Public API
    func seedIfNeeded(in context: ModelContext) async {
        if isSeeded {
            return
        }
        self.modelContext = context

        let airports = airportData()
        let aircrafts = aircraftData()
        let staff = await createStaff(batchIndex: 0)
        let routes = createRoutes()
        let users = await createUser()

        for airport in airports { context.insert(airport) }
        for aircraft in aircrafts { context.insert(aircraft) }
        for staffMember in staff { context.insert(staffMember) }
        for route in routes { context.insert(route) }
        for user in users { context.insert(user) }
        try? context.save()

        let trips = await createTrips(
            routes: routes,
            aircrafts: aircrafts,
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
        } catch {
            print("Failed to seed demo data: \(error)")
        }

    }

    func startAutoUpdates(in context: ModelContext) {
        self.modelContext = context

        // Invalidate any previous timer before creating a new one
        updateTimer?.invalidate()

        // Run immediately on start
        simulateFlightProgression(in: context)

        // Then repeat every 30 seconds on the main run loop
        // so it continues running even when the app is in the foreground
        // navigating between views (timer is held by the singleton, not a view)
        let timer = Timer(timeInterval: 20, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.simulateFlightProgression(in: context)
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }

    func stopAutoUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil

        reseedTimer?.invalidate()
        reseedTimer = nil

        modelContext = nil
    }

    private func simulateFlightProgression(in context: ModelContext) {
        let currentTime = Date()

        do {
            for trip in allTrips {
                if trip.nodeStatuses.isEmpty {
                    // Trip hasn't started yet — depart on time
                    if currentTime >= trip.scheduledDepartureTime {
                        trip.startTrip(
                            departureTime: trip.scheduledDepartureTime
                        )
                    }
                } else {
                    progressTrip(trip, currentTime: currentTime)
                }
            }

            try context.save()
        } catch {
            print("Error during flight simulation: \(error)")
        }
    }
    
    public func resolveExpiredTrips(in context: ModelContext) async {
        let now = Date()

        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { !$0.isCompleted && !$0.isCancelled }
        )

        guard let trips = try? context.fetch(descriptor) else { return }

        for trip in trips {
            if trip.estimatedArrivalTime <= now {
                trip.isCompleted = true

                // Keep aircraft and staff state consistent
                trip.aircraft.updateLastAndNextScheduledTrip(
                    completedTrip: trip
                )
                for staff in trip.staffs {
                    staff.updateLastAndNextScheduledTrip(completedTrip: trip)
                }
            }
        }

        try? context.save()
    }

    private func progressTrip(_ trip: Trip, currentTime: Date) {
        guard !trip.isCancelled && !trip.isCompleted else { return }

        // Catch-up loop: process as many segments as the clock allows in one tick.
        // This handles the case where the app was backgrounded or the simulator
        // skipped a tick — all overdue arrivals/departures are resolved at once.
        while !trip.isCompleted {
            guard let activeNode = trip.activeNodeStatus else { break }

            // ── Phase 1: Arrive at the current target airport ─────────────────
            if activeNode.actualArrivalTime == nil {
                // Arrival time is deterministic: scheduled departure + the node's
                // planned offset. No random jitter — the offset already encodes
                // the full journey time from the source airport.
                let expectedArrival = trip.scheduledDepartureTime
                    .addingTimeInterval(
                        TimeInterval(
                            activeNode.routeNode.plannedArrivalOffsetMinutes
                                * 60
                        )
                    )

                guard currentTime >= expectedArrival else {
                    break  // Still en-route; check again on next timer tick
                }

                trip.scheduleCurrentAirportArrival(arrivalTime: expectedArrival)

                if trip.isCompleted { break }
                // Fall through to Phase 2 in the same iteration
            }

            // ── Phase 2: Depart from the intermediate airport ─────────────────
            // No turnaround time: depart the moment we arrive.
            if activeNode.actualArrivalTime != nil
                && activeNode.actualDepartureTime == nil
            {
                // Only depart if there is a next airport to fly to
                guard trip.currentAirportSequence < trip.route.nodes.count
                else { break }

                let departureTime = activeNode.actualArrivalTime!  // immediate, no turnaround
                trip.scheduleCurrentAirportDeparture(
                    departureTime: departureTime
                )
                // scheduleCurrentAirportDeparture increments currentAirportSequence
                // and appends the next TripNodeStatus, so the next activeNodeStatus
                // lookup will correctly target the new pending node.
            }
        }
    }
}

// MARK: Helpers
extension DemoDataSeeder {
    private func generateFlightNumber(
        route: Route,
        index: Int,
        uniqueRunID: String
    ) -> String {

        let airlineCodes = ["AI", "6E", "UK", "SG", "QP"]
        let airline = airlineCodes.randomElement() ?? "AI"

        let baseNumber = Int.random(in: 100...999)
        let routeHash = abs(route.name.hashValue % 50)

        return "\(airline)\(baseNumber + routeHash + index)-\(uniqueRunID)"
    }

    private static func indianNameAndGender(at index: Int, role: StaffRole) -> (
        String, Gender
    ) {
        let maleIndex = index % indianMaleNames.count
        let femaleIndex = index % indianFemaleNames.count

        let femaleProbability: Int
        switch role {
        case .pilot:
            femaleProbability = 10
        case .coPilot:
            femaleProbability = 15
        case .cabinCrew:
            femaleProbability = 75
        }

        // Random 0–99 distribution
        let isFemale = Int.random(in: 0..<100) < femaleProbability

        if isFemale {
            return (indianFemaleNames[femaleIndex], .female)
        } else {
            return (indianMaleNames[maleIndex], .male)
        }
    }

    private func makeStaff(
        name: String,
        gender: Gender,
        designation: StaffRole,
        yearRange: ClosedRange<Int>,
        emailDomain: [String],
        assetName: String
    ) async -> Staff {
        let email =
            name.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            + emailDomain[Int.random(in: 0..<emailDomain.count)]
        let imgData = imageData(fromAssetName: assetName)
        let profileBgColor: ColorData
        if let data = imgData, let img = UIImage(data: data),
            let dominantColor = await dominantBackgroundColor(from: img)
        {
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
}

// MARK: Data seeders
extension DemoDataSeeder {

    private func createUser() async -> [User] {
        return [
            User(
                name: "Admin",
                email: "admin@gmail.com",
                password: "123456",
                role: .admin
            ),
            User(
                name: "Manager",
                email: "manager@gmail.com",
                password: "123456",
                role: .tripManager
            ),
        ]
    }

    // Staff per batch: 100 (30 pilot, 34 co-pilot, 36 cabin crew). Max 3 batches.
    private func createStaff(batchIndex: Int) async -> [Staff] {

        let pilotCount = 30
        let coPilotCount = 34
        let crewCount = 36

        var staff: [Staff] = []
        var nameOffset = batchIndex * 100
        let maleImageNames = (1...17).map { "image-\($0)-male" }
        let femaleImageNames = (1...17).map { "image-\($0)-female" }

        for i in 0..<pilotCount {
            let (name, gender) = Self.indianNameAndGender(
                at: nameOffset + i,
                role: .pilot
            )

            let s = await makeStaff(
                name: name,
                gender: gender,
                designation: .pilot,
                yearRange: 1995...2000,
                emailDomain: emailDomain,
                assetName: (gender == .male
                    ? maleImageNames.randomElement()
                    : femaleImageNames.randomElement() ?? "default") ?? ""
            )

            staff.append(s)
        }

        nameOffset += pilotCount

        for i in 0..<coPilotCount {
            let (name, gender) = Self.indianNameAndGender(
                at: nameOffset + i,
                role: .coPilot
            )

            let s = await makeStaff(
                name: name,
                gender: gender,
                designation: .coPilot,
                yearRange: 1995...2000,
                emailDomain: emailDomain,
                assetName: (gender == .male
                    ? maleImageNames.randomElement()
                    : femaleImageNames.randomElement() ?? "default") ?? ""
            )

            staff.append(s)
        }

        nameOffset += coPilotCount

        for i in 0..<crewCount {
            let (name, gender) = Self.indianNameAndGender(
                at: nameOffset + i,
                role: .cabinCrew
            )

            let s = await makeStaff(
                name: name,
                gender: gender,
                designation: .cabinCrew,
                yearRange: 1995...2000,
                emailDomain: emailDomain,
                assetName: (gender == .male
                    ? maleImageNames.randomElement()
                    : femaleImageNames.randomElement() ?? "default") ?? ""
            )
            staff.append(s)
        }

        return staff
    }

    private func createRoutes() -> [Route] {

        func airport(_ code: String) -> Airport {
            airportData().first { $0.code == code }!
        }

        let routeDefinitions: [(name: String, stops: [String])] = [

            ("Delhi–Mumbai Shuttle", ["DEL", "BOM"]),
            ("Golden Triangle", ["DEL", "JAI", "VNS"]),
            ("South India Express", ["BLR", "MAA", "COK", "TRV"]),
            ("North-East Connector", ["DEL", "GAU", "IMF", "IXA"]),
            ("Western Ghats Flyer", ["BOM", "GOX", "COK", "BLR"]),
            ("Kerala–Capital", ["TRV", "COK", "DEL"]),
            ("Kashmir–Capital Link", ["SXR", "DEL"]),
            ("Eastern Seaboard Corridor", ["CCU", "BBI", "VTZ", "MAA"]),
            ("Rajasthan Discovery", ["DEL", "JAI", "UDR", "JDH"]),
            ("Deccan Link", ["HYD", "BLR", "PNQ", "BOM"]),
            ("Bay of Bengal Route", ["CCU", "VTZ", "MAA"]),
            ("Punjab–Maharashtra Corridor", ["ATQ", "DEL", "BOM"]),
            ("Andaman Gateway", ["DEL", "CCU", "IXZ"]),
            ("Gujarat–Karnataka Express", ["AMD", "BLR"]),
            ("Uttar Pradesh Express", ["DEL", "LKO", "VNS"]),
        ]

        var routes: [Route] = []

        for definition in routeDefinitions {

            let route = Route(name: definition.name)

            for (index, code) in definition.stops.enumerated() {

                let airport = airport(code)

                if index == 0 {
                    route.addNode(
                        airport: airport,
                        journeyTimeMinutes: 0,
                        turnAroundTimeMinutes: 0
                    )
                } else {
                    // taking small journey time for data simulation in app
                    let journeyTime = Int.random(in: 3...25)

                    route.addNode(
                        airport: airport,
                        journeyTimeMinutes: journeyTime,
                        turnAroundTimeMinutes: 0
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
        currentDate: Date
    ) async -> [Trip] {

        var trips: [Trip] = []

        for (routeIndex, route) in routes.enumerated() {

            // 10 trips in next 6 hours (every 6 minutes)
            let sixHourTrips = stride(from: 0, to: 360, by: 6).map {
                currentDate.addingTimeInterval(TimeInterval($0 * 60))
            }

            // 30 trips in next 24 hours (after first 6 hours)
            let twentyFourHourTrips = stride(from: 360, to: 1440, by: 36)
                .prefix(30).map {
                    currentDate.addingTimeInterval(TimeInterval($0 * 60))
                }

            let allScheduleTimes = sixHourTrips + twentyFourHourTrips

            for (tripIndex, scheduledTime) in allScheduleTimes.enumerated() {

                let endTime = scheduledTime.addingTimeInterval(
                    TimeInterval(route.totalPlannedDurationMinutes * 60)
                )

                let availablePilots = pilots.filter {
                    $0.isAvailable(from: scheduledTime, to: endTime)
                }

                let availableCoPilots = coPilots.filter {
                    $0.isAvailable(from: scheduledTime, to: endTime)
                }

                let availableCrew = crew.filter {
                    $0.isAvailable(from: scheduledTime, to: endTime)
                }

                let availableStaffCounts: [StaffRole: Int] = [
                    .pilot: availablePilots.count,
                    .coPilot: availableCoPilots.count,
                    .cabinCrew: availableCrew.count,
                ]

                let availableAircraft = aircrafts.filter {
                    $0.isAvailable(
                        from: scheduledTime,
                        to: endTime,
                        availableStaff: availableStaffCounts
                    )
                }

                guard let aircraft = availableAircraft.randomElement() else {
                    continue
                }

                let pilotsRequired = aircraft.minimumStaffRequired[.pilot] ?? 1
                let coPilotsRequired =
                    aircraft.minimumStaffRequired[.coPilot] ?? 0
                let crewRequired =
                    aircraft.minimumStaffRequired[.cabinCrew] ?? 1

                guard availablePilots.count >= pilotsRequired,
                    availableCoPilots.count >= coPilotsRequired,
                    availableCrew.count >= crewRequired
                else {
                    continue
                }

                var assignedStaff: [Staff] = []
                assignedStaff += availablePilots.shuffled().prefix(
                    pilotsRequired
                )
                assignedStaff += availableCoPilots.shuffled().prefix(
                    coPilotsRequired
                )
                assignedStaff += availableCrew.shuffled().prefix(crewRequired)

                let flightNumber = "FL-\(routeIndex)-\(tripIndex)"

                let trip = Trip(
                    staff: assignedStaff,
                    aircraft: aircraft,
                    nodeStatuses: [],
                    route: route,
                    scheduledDepartureTime: scheduledTime,
                    tripNumber: flightNumber,
                    isCancelled: false
                )

                assignedStaff.forEach { $0.trips.append(trip) }
                aircraft.trips.append(trip)
                trips.append(trip)
            }
        }

        return trips
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
