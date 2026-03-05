import Foundation

enum UserRole: String, Codable, CaseIterable {
    case admin = "Admin"
    case tripManager = "Trip Manager"
}

enum StaffRole: String, Codable, CaseIterable {
    case pilot = "Pilot"
    case coPilot = "Co-Pilot"
    case cabinCrew = "Cabin Crew"
}

enum SortOrder: String, CaseIterable {
    case ascending = "Ascending"
    case descending = "Descending"
}

enum TripStatus: String, Codable, CaseIterable {
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
    case deCommissioned = "De-commissioned"
}

enum RouteStatus: String, CaseIterable {
    case inactive = "Inactive"
    case active = "Active"
}

enum Gender: String, Codable, CaseIterable {
    case male, female, other

    var description: String {
        return self.rawValue.capitalized
    }
}

enum StaffSort: String, CaseIterable {
    case name = "Name"
    case experience = "Experience"
}

enum RouteSort: String, CaseIterable {
    case name = "Name"
    case tripsCount = "Trips Count"
}

enum TripSort: String, CaseIterable {
    case flightNumber = "Flight Number"
    case departure = "Departure Time"
}

enum AircraftSort: String, CaseIterable {
    case registration = "Registration Number"
    case seatingCapacity = "Seating Capacity"
}

enum FieldError: Hashable {
    case name, email, gender, role, date
    case registrationNumber, type, seatingCapacity, minimumStaffRequired
    case code, city, country
    case airports, journeyTime
    case password, confirmPassword
}

enum SubmissionState: Equatable {
    case success, none, error
}

enum FormFocus: Hashable {
    case name, email, gender, role, date
    case registrationNumber, type, seatingCapacity
    case code, city, country
    case routeName, journeyTime
    case password, confirmPassword
    case flightNumber
}

enum NotificationType: Equatable {
    case success(message: String)
    case error(message: String)
    case none
}

