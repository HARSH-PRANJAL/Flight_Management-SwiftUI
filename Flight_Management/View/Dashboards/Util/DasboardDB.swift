import Foundation
import SwiftData

enum DashboardDB {
    static func todayTripsPredicate() -> Predicate<Trip> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return #Predicate<Trip> {
            $0.scheduledDepartureTime >= startOfDay &&
            $0.scheduledDepartureTime < endOfDay
        }
    }

    static func upcomingTripsPredicate(withinHours hours: Int) -> Predicate<Trip> {
        let now = Date()
        let until = Calendar.current.date(byAdding: .hour, value: hours, to: now) ?? now
        return #Predicate<Trip> {
            !$0.isCompleted &&
            $0.scheduledDepartureTime >= now &&
            $0.scheduledDepartureTime <= until
        }
    }

    static var availableStaffPredicate: Predicate<Staff> {
        #Predicate<Staff> { !$0.isMarkedUnavailable && $0.currentTrip == nil }
    }

    static var onDutyStaffPredicate: Predicate<Staff> {
        #Predicate<Staff> { !$0.isMarkedUnavailable && $0.currentTrip != nil }
    }
    
    static var unavailableStaffPredicate: Predicate<Staff> {
        #Predicate<Staff> { $0.isMarkedUnavailable }
    }
}
