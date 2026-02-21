import SwiftUI
import UIKit

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

struct ColorData: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    init(uiColor: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    var swiftUIColor: Color {
        Color(
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
    }
}
