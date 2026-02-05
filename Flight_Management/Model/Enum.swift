enum UserRole: String, Codable {
    case admin = "ADMIN"
    case tripManager = "TRIP_MANAGER"
    case crew = "CREW"
}

enum StaffRole: String, Codable {
    case pilot = "PILOT"
    case coPilot = "CO_PILOT"
    case cabinCrew = "CABIN_CREW"
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
