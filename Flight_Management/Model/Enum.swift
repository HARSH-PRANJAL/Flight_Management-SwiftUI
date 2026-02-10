import Foundation

enum UserRole: String, Codable {
    case admin = "Admin"
    case tripManager = "Trip Manager"
    case crew = "Crew"
}

enum StaffRole: String, Codable, CaseIterable {
    case pilot = "Pilot"
    case coPilot = "Co-Pilot"
    case cabinCrew = "Cabin Crew"
}

enum TripStatus: String, Codable {
    case scheduled = "Scheduled"
    case onTime = "On-time"
    case delayed = "Delayed"
    case cancelled = "Canceled"
    case completed = "Completed"
}

enum StaffAvailabilityStatus: String, Codable, CaseIterable {
    case available = "Available"
    case onDuty = "On-duty"
    case unavailable = "Unavailable"
}

enum AircraftStatus: String, Codable {
    case available = "Available"
    case assigned = "Assigned"
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
    
    var monthNumber: Int {
        switch self {
        case .jan: return 1
        case .feb: return 2
        case .march: return 3
        case .april: return 4
        case .may: return 5
        case .june: return 6
        case .jul: return 7
        case .aug: return 8
        case .sep: return 9
        case .oct: return 10
        case .nov: return 11
        case .dec: return 12
        }
    }
}

enum StaffSort: String, CaseIterable {
    case name = "Name"
    case experience = "Experience"
}

