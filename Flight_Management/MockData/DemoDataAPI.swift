import Foundation
import SwiftData

/// Simple helpers to use the DemoDataSeeder from the app.
public enum DemoDataAPI {
    /// Seed demo data if not already seeded
    public static func seedIfNeeded(in context: ModelContext) async {
        await DemoDataSeeder.shared.seedIfNeeded(in: context)
    }

    /// Force reseed
    public static func forceReseed(in context: ModelContext) async {
        await DemoDataSeeder.shared.forceReseed(in: context)
    }

    /// Start periodic demo updates
    public static func startAutoUpdates(in context: ModelContext) {
        DemoDataSeeder.shared.startAutoUpdates(in: context)
    }

    /// Stop periodic demo updates
    public static func stopAutoUpdates() {
        DemoDataSeeder.shared.stopAutoUpdates()
    }
}
