import SwiftUI
import SwiftData

struct AircraftDetailView: View {
    let aircraft: Aircraft
    
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.modelContext) var modelContext
    
    @State private var isEditPageShowing: Bool = false
    
    var isTripManager: Bool {
        session.user?.role == UserRole.tripManager.rawValue
    }
    
    var isAircraftAvailable: Bool {
        aircraft.currentStatus == .available
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            DetailView(aircraft: aircraft)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar(.hidden, for: .bottomBar)
        }
        .toolbar {
            if isTripManager && isAircraftAvailable {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isEditPageShowing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditPageShowing) {
            NavigationStack {
                AircraftRegistrationContent(aircraft: aircraft, isPresented: $isEditPageShowing)
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
