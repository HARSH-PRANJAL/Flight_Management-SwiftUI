import SwiftUI
import SwiftData

@main
struct FlightManagementApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Route.self, RouteNode.self, Airport.self, Trip.self, TripNodeStatus.self, Aircraft.self, Staff.self], isAutosaveEnabled: true)
        }
    }
}
