import Foundation

enum UserRole: String, Codable {
    case admin = "ADMIN"
    case tripManager = "TRIP MANAGER"
    case crew = "CREW"
}

enum StaffRole: String, Codable, CaseIterable {
    case pilot = "PILOT"
    case coPilot = "CO-PILOT"
    case cabinCrew = "CABIN CREW"
}

enum TripStatus: String, Codable {
    case scheduled = "SCHEDULED"
    case onTime = "ON_TIME"
    case delayed = "DELAYED"
    case cancelled = "CANCELLED"
    case completed = "COMPLETED"
}

enum StaffAvailabilityStatus: String, Codable {
    case available = "AVAILABLE"
    case onDuty = "ON_DUTY"
    case unavailable = "UNAVAILABLE"
}

enum AircraftStatus: String, Codable {
    case available = "AVAILABLE"
    case assigned = "ASSIGNED"
}

enum Gender: String, Codable, CaseIterable {
    case male, female, other

    var description: String {
        return self.rawValue.capitalized
    }
}

enum Month: String, Codable, CaseIterable {
    case jan = "January"
    case feb = "February"
    case march = "March"
    case april = "April"
    case may = "May"
    case june = "June"
    case jul = "July"
    case aug = "August"
    case sep = "September"
    case oct = "October"
    case nov = "November"
    case dec = "December"

    var numberOfDays: Int {
        switch self {
        case .april, .june, .sep, .nov:
            return 30
        case .feb:
            return 29
        default:
            return 31
        }
    }
    
    static func numberOfDays(inMonth month: String) -> Int {
        
        for monthString in Month.allCases {
            if monthString.rawValue.lowercased() == month.lowercased() {
                return monthString.numberOfDays
            }
        }
        
        return 31
    }
}
