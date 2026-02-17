import SwiftUI

struct AircraftDetailView: View {
    let aircraft: Aircraft

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            DetailView(aircraft: aircraft)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar(.hidden, for: .bottomBar)
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
