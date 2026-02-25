import Foundation
import SwiftData

/// Simple helpers to use the DemoDataSeeder from the app.
public enum DemoDataAPI {
    /// Seed demo data if not already seeded
    public static func seedIfNeeded(in context: ModelContext) async {
        await DemoDataSeeder.shared.seedIfNeeded(in: context)
    }

    /// Start periodic demo updates
    public static func startAutoUpdates(in context: ModelContext) {
        DemoDataSeeder.shared.startAutoUpdates(in: context)
    }

    /// Stop periodic demo updates
    public static func stopAutoUpdates() {
        DemoDataSeeder.shared.stopAutoUpdates()
    }

    /// Delete all existing trips from database
    public static func deleteAllTrips(in context: ModelContext) async {
        try? context.delete(model: Trip.self)
        try? context.save()
    }

    /// Start flight simulator
    public static func startFlightSimulator(in context: ModelContext) {
        DemoDataSeeder.shared.startAutoUpdates(in: context)
    }

    /// Stop flight simulator
    public static func stopFlightSimulator() {
        DemoDataSeeder.shared.stopAutoUpdates()
    }
}
