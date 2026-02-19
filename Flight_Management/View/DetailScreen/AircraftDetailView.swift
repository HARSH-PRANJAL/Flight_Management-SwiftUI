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

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            AircraftDetailScreen(aircraft: aircraft,isManager: isTripManager, isEditPagePresented: $isEditPageShowing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar(.hidden, for: .tabBar)
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
