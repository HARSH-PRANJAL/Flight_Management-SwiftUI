import SwiftUI

struct AircraftDetailView: View {
    let aircraft: Aircraft

    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.modelContext) var modelContext

    @State private var isEditPageShowing: Bool = false
    @State var isScheduledTripsPresented: Bool = false

    var isTripManager: Bool {
        session.user?.role == UserRole.tripManager.rawValue
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            AircraftDetailScreen(
                aircraft: aircraft,
                isManager: isTripManager,
                isEditPagePresented: $isEditPageShowing,
                isScheduledTripsPresented: $isScheduledTripsPresented
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .tabBar)
        }
        .sheet(
            isPresented: Binding(
                get: { isEditPageShowing || isScheduledTripsPresented },
                set: { newValue in
                    if !newValue {
                        isEditPageShowing = false
                        isScheduledTripsPresented = false
                    }
                }
            )
        ) {
            if isEditPageShowing {
                NavigationStack {
                    AircraftRegistrationContent(
                        aircraft: aircraft,
                        isPresented: $isEditPageShowing
                    )
                }
            } else if isScheduledTripsPresented {
                NavigationStack {
                    TripList(
                        externalTrips: aircraft.scheduledTrips,
                        navigationTitle: "Scheduled Trips",
                        requiredFilters: []
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .padding(.top, -20)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                isScheduledTripsPresented.toggle()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AircraftDetailView(
            aircraft: Aircraft(
                registrationNumber: "N12345",
                type: "Boeing 737",
                seatingCapacity: 180,
                minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 4]
            )
        )
    }
}
