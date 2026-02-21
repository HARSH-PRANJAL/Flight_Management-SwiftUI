import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(SessionManager.self) var sessionManager
    @Environment(\.dismiss) var dismiss

    var trip: Trip

    @State private var showCancellationAlert = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""

    var isTripManager: Bool {
        sessionManager.user?.role == UserRole.tripManager.rawValue
    }

    var tripHasStarted: Bool {
        !trip.nodeStatuses.isEmpty
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            TripDetailScreen(
                trip: trip,
                onCancelTapped: isTripManager
                    ? { showCancellationAlert = true } : nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .tabBar)
        }
        .alert("Cancel Trip", isPresented: $showCancellationAlert) {
            Button("Cancel Trip", role: .destructive) {
                performCancellation()
            }
            Button("Keep Trip", role: .cancel) {}
        } message: {
            if tripHasStarted {
                Text(
                    "This trip is currently ongoing. Are you sure you want to cancel it anyway?"
                )
            } else {
                Text("Are you sure you want to cancel this trip?")
            }
        }
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }

    private func performCancellation() {
        trip.cancel()
        do {
            try modelContext.save()
        } catch {}
        successMessage =
            "Trip \(trip.flightNumber) has been cancelled successfully."
        showSuccessMessage = true
    }
}

#Preview {
    let mockRoute = Route(name: "New York to London")
    mockRoute.nodes = [
        RouteNode(
            plannedArrivalOffsetMinutes: 120,
            airport: Airport(
                code: "JFK",
                name: "John F. Kennedy",
                city: "New York",
                country: "USA"
            ),
            sequence: 1
        ),
        RouteNode(
            plannedArrivalOffsetMinutes: 480,
            airport: Airport(
                code: "LHR",
                name: "London Heathrow",
                city: "London",
                country: "UK"
            ),
            sequence: 2
        ),
    ]

    let mockAircraft = Aircraft(
        registrationNumber: "N12345",
        type: "Boeing 737",
        seatingCapacity: 180,
        minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 5]
    )

    let mockStaff = Staff(
        name: "John Doe",
        designation: .pilot,
        gender: .male,
        email: "john@example.com",
        dob: Date()
    )

    let mockTrip = Trip(
        staff: [mockStaff],
        aircraft: mockAircraft,
        nodeStatuses: [],
        route: mockRoute,
        scheduledDepartureTime: Date().addingTimeInterval(3600),
        flightNumber: "AA-100",
        isCancelled: false
    )

    return TripDetailView(trip: mockTrip)
        .environment(SessionManager.shared)
}
