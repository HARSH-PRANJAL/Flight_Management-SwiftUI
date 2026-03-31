import SwiftData
import SwiftUI

struct StaffDetailView: View {
    let staff: Staff
    var onShowTrip: ((Trip) -> Void)? = nil

    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.modelContext) var modelContext

    @State var isEditPageShowing: Bool = false
    @State var showReplaceStaffSheet: Bool = false
    @State var isScheduledTripsPresented: Bool = false

    // Alert states
    @State var showMarkUnavailableAlert: Bool = false
    @State var showReplacementConfirmationAlert: Bool = false
    @State var showNoReplacementAlert: Bool = false

    // Data for flow
    @State var availableReplacementStaff: [Staff] = []
    @State var selectedReplacementStaff: Staff?
    @State var scheduledTripsToCancel: [Trip] = []

    var isAdmin: Bool {
        session.user?.role == UserRole.admin.rawValue
    }

    var isStaffOnDuty: Bool {
        staff.currentStatus == .onDuty
    }

    var hasScheduledTrips: Bool {
        !staff.scheduledTrips.isEmpty
    }

    var tripString: String {
        if staff.scheduledTrips.count <= 1 {
            return "trip"
        }

        return "trips"
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            StaffDetailScreen(
                staff: staff,
                isAdmin: isAdmin,
                onShowTrip: onShowTrip,
                onActionButtonTapped: isAdmin ? { handleAdminAction() } : nil,
                isScheduledTripsPresented: $isScheduledTripsPresented,
                isEditPageShowing: $isEditPageShowing
            ).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $isEditPageShowing) {
            NavigationStack {
                StaffRegistrationForm(
                    staff: staff,
                    isPresented: $isEditPageShowing
                )
            }
        }
        .sheet(isPresented: $isScheduledTripsPresented) {
            NavigationStack {
                TripList(
                    externalTrips: staff.scheduledTrips,
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
        .sheet(isPresented: $showReplaceStaffSheet) {
            ReplaceStaffSheet(
                currentStaff: staff,
                availableStaffList: availableReplacementStaff,
                onReplacement: { replacement in
                    selectedReplacementStaff = replacement
                    showReplacementConfirmationAlert = true
                }
            )
        }
        .alert("", isPresented: $showMarkUnavailableAlert) {
            Button("Cancel", role: .cancel) {}
            if isStaffOnDuty {
                Button(
                    "Find Replacement",
                    role: .confirm,
                    action: findReplacementStaff
                )
            } else {
                Button(
                    "Mark Unavailable",
                    role: .destructive,
                    action: markStaffUnavailableIncludingCurrentTrip
                )
            }
        } message: {
            if isStaffOnDuty {
                Text(
                    "\(staff.name) is currently assigned to a trip. \(staff.scheduledTrips.count != 0 ? "Additionally, they have \(staff.scheduledTrips.count) scheduled \(tripString) that will be canceled." : "")\n\nWould you like to find a replacement for current trip ?"
                )
            } else {
                Text(
                    "\(staff.name) has \(staff.scheduledTrips.count) scheduled \(tripString) that will be canceled."
                )

            }
        }
        // Alert: Replacement found - confirm assignment
        .alert(
            "",
            isPresented: $showReplacementConfirmationAlert
        ) {
            Button("Assign", action: proceedWithReplacement)
            Button("Cancel", role: .cancel) {
                selectedReplacementStaff = nil
            }
        } message: {
            if let replacement = selectedReplacementStaff {
                Text(
                    "Assign \(replacement.name) as replacement for \(staff.name)?"
                )
            }
        }
        // Alert: No replacement available
        .alert("No Replacement Available", isPresented: $showNoReplacementAlert)
        {
            Button(
                "Mark Unavailable",
                role: .destructive,
                action: markStaffUnavailableIncludingCurrentTrip
            )
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "No available staff with designation \(staff.designation.rawValue) is found. All scheduled trips will be canceled."
            )
        }
    }
}

// MARK: Util
extension StaffDetailView {
    private func handleAdminAction() {
        if staff.isMarkedUnavailable {
            markStaffAvailable()
        } else {
            initiateMarkUnavailable()
        }
    }

    private func initiateMarkUnavailable() {
        if staff.scheduledTrips.isEmpty && staff.currentStatus != .onDuty{
            markStaffUnavailable()
        } else {
            scheduledTripsToCancel = staff.scheduledTrips
            showMarkUnavailableAlert = true
        }
    }

    private func findReplacementStaff() {
        do {
            let designation = staff.designation
            let staffID = staff.id

            let predicate = #Predicate<Staff> { candidate in
                candidate.id != staffID
                    && candidate.isMarkedUnavailable == false
            }

            let descriptor = FetchDescriptor<Staff>(predicate: predicate)
            let fetched = try modelContext.fetch(descriptor)

            availableReplacementStaff = fetched.filter {
                $0.designation == designation
                    && $0.isAvailable(
                        from: staff.currentTrip?.scheduledDepartureTime
                            ?? Date(),
                        to: staff.currentTrip?.estimatedArrivalTime ?? Date()
                    )
            }

            if availableReplacementStaff.isEmpty {
                showNoReplacementAlert = true
            } else {
                showReplaceStaffSheet = true
            }

        } catch {
            notificationManager.showError(
                "Failed to find replacement staff: \(error.localizedDescription)"
            )
        }
    }

    private func proceedWithReplacement() {
        guard let replacement = selectedReplacementStaff,
            let currentTrip = staff.currentTrip
        else {
            selectedReplacementStaff = nil
            return
        }

        // Assign replacement to the current trip
        if let index = currentTrip.staffs.firstIndex(where: {
            $0.id == staff.id
        }) {
            currentTrip.staffs[index] = replacement
            replacement.trips.append(currentTrip)
            replacement.currentTrip = currentTrip
        }

        // Cancel all scheduled trips and mark original staff unavailable
        markStaffUnavailableWithCancellation()
        selectedReplacementStaff = nil
    }

    private func markStaffUnavailableWithCancellation() {
        for trip in scheduledTripsToCancel {
            trip.cancel()
        }
        markStaffUnavailable()
    }

    private func markStaffUnavailableIncludingCurrentTrip() {
        if let current = staff.currentTrip {
            scheduledTripsToCancel.append(current)
        }
        markStaffUnavailableWithCancellation()
    }

    private func markStaffUnavailable() {
        staff.markUnavailable()

        do {
            try modelContext.save()
            notificationManager.showSuccess(
                "\(staff.name) has been marked as unavailable"
            )
        } catch {
            notificationManager.showError("Failed to mark staff as unavailable")
            staff.isMarkedUnavailable = false
        }
    }

    private func markStaffAvailable() {
        staff.isMarkedUnavailable = false

        do {
            try modelContext.save()
            notificationManager.showSuccess(
                "\(staff.name) has been marked as available"
            )
        } catch {
            notificationManager.showError("Failed to mark staff as available")
            staff.isMarkedUnavailable = true
        }
    }
}

#Preview {
    NavigationStack {
        StaffDetailView(
            staff: Staff(
                name: "Captain John Doe",
                designation: .pilot,
                gender: .male,
                email: "john@example.com",
                dob: Date()
            )
        )
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
    }
}
