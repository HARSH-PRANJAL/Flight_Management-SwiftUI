import SwiftUI
import SwiftData

struct StaffDetailView: View {
    let staff: Staff
    
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.modelContext) var modelContext
    
    @State var isEditPageShowing: Bool = false
    @State var showReplaceStaffSheet: Bool = false
    
    // Alert states
    @State var showStaffOnDutyAlert: Bool = false
    @State var showReplacementConfirmationAlert: Bool = false
    @State var showNoReplacementAlert: Bool = false
    @State var showTripCancellationAlert: Bool = false
    @State var showMinimumStaffAlert: Bool = false
    
    // Data for flow
    @State var availableReplacementStaff: [Staff] = []
    @State var selectedReplacementStaff: Staff?
    @State var scheduledTripsToCancel: [Trip] = []
    
    var isCurrentUser: Bool {
        session.user?.id == staff.id.uuidString
    }
    
    var isAdmin: Bool {
        session.user?.role == UserRole.admin.rawValue
    }
    
    var profileImage: Image? {
        if let imageData = staff.profileImage,
           let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
    
    var isStaffOnDuty: Bool {
        staff.currentTrip != nil
    }
    
    var hasScheduledTrips: Bool {
        !staff.scheduledTrips.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            DetailView(
                staff: staff,
                onTapAction: isCurrentUser ? { isEditPageShowing = true } : (isAdmin ? { handleAdminAction() } : nil),
                actionButtonTitle: isCurrentUser ? "Update Profile" : (isAdmin ? (staff.isMarkedUnavailable ? "Mark Active" : "Mark Unavailable") : "")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .bottomBar)
        }
        
        .sheet(isPresented: $isEditPageShowing) {
            StaffRegistrationForm(staff: staff, isPresented: $isEditPageShowing)
        }
        
        .sheet(isPresented: $showReplaceStaffSheet) {
            ReplaceStaffSheet(
                currentStaff: staff,
                availableStaffList: availableReplacementStaff,
                onReplacement: { replacement in
                    selectedReplacementStaff = replacement
                    handleReplacementSelected()
                }
            )
        }
        
        // Alert: Staff is on active duty
        .alert("Staff On Active Duty", isPresented: $showStaffOnDutyAlert) {
            Button("Find Replacement", action: findReplacementStaff)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(staff.name) is currently assigned to a trip. Would you like to find a replacement staff?")
        }
        
        // Alert: Replacement found - confirm assignment
        .alert("Assign Replacement", isPresented: $showReplacementConfirmationAlert) {
            Button("Assign", action: proceedWithReplacement)
            Button("Cancel", role: .cancel) {
                selectedReplacementStaff = nil
            }
        } message: {
            if let replacement = selectedReplacementStaff {
                Text("Assign \(replacement.name) as replacement for \(staff.name)?")
            }
        }
        
        // Alert: No replacement available
        .alert("No Replacement Available", isPresented: $showNoReplacementAlert) {
            Button("Check Minimum Requirement", action: checkMinimumStaffRequirement)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("No available staff with \(staff.designation.rawValue) designation found.")
        }
        
        // Alert: Trip cancellation warning
        .alert("Trip Cancellation Warning", isPresented: $showTripCancellationAlert) {
            Button("Cancel Trip(s)", role: .destructive, action: cancelScheduledTripsAndMarkUnavailable)
            Button("Keep Trip(s)", role: .cancel) {}
        } message: {
            Text("\(staff.name) is scheduled on \(scheduledTripsToCancel.count) upcoming trip(s). Marking unavailable will cancel these trips. Continue anyway?")
        }
        
        // Alert: Minimum staff requirement check
        .alert("Minimum Staff Requirement", isPresented: $showMinimumStaffAlert) {
            Button("Mark Unavailable Anyway", role: .destructive, action: markStaffUnavailable)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Marking \(staff.name) as unavailable may not meet minimum staff requirements for scheduled trips.")
        }
    }
    
    private func handleAdminAction() {
        if staff.isMarkedUnavailable {
            markStaffAvailable()
        } else {
            initiateMarkUnavailable()
        }
    }
    
    private func initiateMarkUnavailable() {
        if isStaffOnDuty {
            showStaffOnDutyAlert = true
        } else {
            checkScheduledTripsAndMarkUnavailable()
        }
    }
    
    private func checkScheduledTripsAndMarkUnavailable() {
        scheduledTripsToCancel = staff.scheduledTrips
        
        if !scheduledTripsToCancel.isEmpty {
            showTripCancellationAlert = true
        } else {
            markStaffUnavailable()
        }
    }
    
    private func findReplacementStaff() {
        do {
            let designation = staff.designation
            let staffID = staff.id
            
            let predicate = #Predicate<Staff> { candidate in
                candidate.id != staffID &&
                candidate.isMarkedUnavailable == false
            }
            
            let descriptor = FetchDescriptor<Staff>(predicate: predicate)
            let fetched = try modelContext.fetch(descriptor)
            
            availableReplacementStaff = fetched.filter {
                $0.designation == designation &&
                $0.currentTrip == nil
            }
            
            if availableReplacementStaff.isEmpty {
                showNoReplacementAlert = true
            } else {
                showReplaceStaffSheet = true
            }
            
        } catch {
            notificationManager.showError("Failed to find replacement staff: \(error.localizedDescription)")
        }
    }
    
    
    
    private func handleReplacementSelected() {
        showReplacementConfirmationAlert = true
    }
    
    private func proceedWithReplacement() {
        guard let replacement = selectedReplacementStaff, let currentTrip = staff.currentTrip else {
            selectedReplacementStaff = nil
            return
        }
        
        // Assign replacement to the current trip
        if let index = currentTrip.staffs.firstIndex(where: { $0.id == staff.id }) {
            currentTrip.staffs[index] = replacement
            replacement.trips.append(currentTrip)
            replacement.currentTrip = currentTrip
        }
        
        // Mark original staff unavailable
        checkScheduledTripsAndMarkUnavailable()
        selectedReplacementStaff = nil
    }
    
    private func checkMinimumStaffRequirement() {
        // For trips that staff is assigned to, check if removing them would violate minimum requirements
        showMinimumStaffAlert = true
    }
    
    private func cancelScheduledTripsAndMarkUnavailable() {
        for trip in scheduledTripsToCancel {
            trip.cancel()
        }
        markStaffUnavailable()
    }
    
    private func markStaffUnavailable() {
        staff.markUnavailable()
        
        do {
            try modelContext.save()
            notificationManager.showSuccess("\(staff.name) has been marked as unavailable")
        } catch {
            notificationManager.showError("Failed to mark staff as unavailable")
            staff.isMarkedUnavailable = false
        }
    }
    
    private func markStaffAvailable() {
        staff.isMarkedUnavailable = false
        
        do {
            try modelContext.save()
            notificationManager.showSuccess("\(staff.name) has been marked as available")
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

