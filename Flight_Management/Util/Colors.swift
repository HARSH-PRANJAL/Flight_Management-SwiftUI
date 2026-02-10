import SwiftUI

extension Color {
    
    static let scheduled    = Color("StatusScheduled")
    static let onTime       = Color("StatusOnTime")
    static let delayed      = Color("StatusDelayed")
    static let cancelled    = Color("StatusCancelled")
    static let completed    = Color("StatusCompleted")
    
    static func tripStatusColor(for status: TripStatus) -> Color {
        switch status {
        case .scheduled:  return .scheduled
        case .onTime:     return .onTime
        case .delayed:    return .delayed
        case .cancelled:  return .cancelled
        case .completed:  return .completed
        }
    }
    
    static func staffStatusColor(for status: StaffAvailabilityStatus) -> Color {
        switch status {
        case .available:   return .onTime
        case .onDuty:      return .completed
        case .unavailable: return .cancelled
        }
    }
    
    static func aircraftStatusColor(for status: AircraftStatus) -> Color {
        switch status {
        case .available:
            return .onTime
        case .assigned:
            return .completed
        }
    }
}
