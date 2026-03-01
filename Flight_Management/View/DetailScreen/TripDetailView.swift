import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(SessionManager.self) var sessionManager
    @Environment(NotificationManager.self) var notification
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
        .navigationTitle("\(trip.flightNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .alert("", isPresented: $showCancellationAlert) {
            Button("Cancel Trip", role: .destructive) {
                performCancellation()
                notification.showSuccess(
                    "\(trip.flightNumber) is canceled successfully."
                )
                dismiss()
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
