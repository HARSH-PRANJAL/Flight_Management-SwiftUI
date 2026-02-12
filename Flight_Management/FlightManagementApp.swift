import SwiftUI
import SwiftData

@main
struct FlightManagementApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for:
                    Route.self,
                RouteNode.self,
                Airport.self,
                Trip.self,
                TripNodeStatus.self,
                Aircraft.self,
                Staff.self,
                User.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .modelContainer(container)
        }
    }
}
