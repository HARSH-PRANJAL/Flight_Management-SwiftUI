import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(SessionManager.self) var sessionManager
    @Environment(\.dismiss) var dismiss
    
    var trip: Trip
    
    @State private var showCancellationAlert = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var isCancelationDisabled = false
    @State private var isEditPageShowing: Bool = false
    
    var isTripManager: Bool {
        sessionManager.user?.role == UserRole.tripManager.rawValue
    }
    
    var canCancelTrip: Bool {
        !trip.isCancelled && !trip.isCompleted && isTripManager
    }
    
    var tripHasStarted: Bool {
        !trip.nodeStatuses.isEmpty
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    primaryCard
                        .padding(.bottom, 10)

                    if canCancelTrip {
                        cancelButton
                            .shadow(
                                color: Color.black.opacity(0.07),
                                radius: 2,
                                x: 0,
                                y: 2
                            )
                    }

                    if !trip.staffs.isEmpty {
                        assignedStaffCard
                    }
                }
                .padding(.horizontal, 15)
            }
            .scrollIndicators(.hidden)
        }
        .alert("Cancel Trip", isPresented: $showCancellationAlert) {
            Button("Cancel Trip", role: .destructive) {
                performCancellation()
            }
            Button("Keep Trip", role: .cancel) {}
        } message: {
            if tripHasStarted {
                Text("This trip is currently ongoing. Are you sure you want to cancel it anyway?")
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
        .toolbar {
            if isTripManager {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isEditPageShowing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditPageShowing) {
            TripRegistrationForm(trip: trip, isPresented: $isEditPageShowing)
        }
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Text(trip.flightNumber)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            Text(trip.route.name)
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 8) {
                DetailRowView(
                    label: "Aircraft",
                    value: trip.aircraft.type
                )
                DetailRowView(
                    label: "Registration",
                    value: trip.aircraft.registrationNumber
                )
                DetailRowView(
                    label: "Scheduled Departure",
                    value: trip.scheduledDepartureTime.formatted(date: .abbreviated, time: .shortened)
                )
                DetailRowView(
                    label: "Estimated Arrival",
                    value: trip.estimatedArrivalTime.formatted(date: .abbreviated, time: .shortened)
                )
                if trip.totalDelayedMinutes > 0 {
                    DetailRowView(
                        label: "Total Delay",
                        value: "\(trip.totalDelayedMinutes) minutes"
                    )
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
            
            StatusCapsuleView(statusBadge: StatusBadge.from(tripStatus: trip.currentStatus))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }

    var cancelButton: some View {
        Text("Cancel Trip")
            .font(.title3)
            .foregroundColor(.red)
            .contrast(1.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                cardTheme()
            )
            .onTapGesture {
                showCancellationAlert = true
            }
            .padding(.bottom, 30)
            .opacity(isCancelationDisabled ? 0.5 : 1.0)
            .disabled(isCancelationDisabled)
    }

    var assignedStaffCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label {
                Text("Flight Crew")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: "person.2")
                    .foregroundStyle(Color(.systemBlue))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            LazyVStack(spacing: 0) {
                ForEach(trip.staffs) { staff in
                    NavigationLink(destination: DetailView(staff: staff)) {
                        ListRow(
                            profileImage: staff.avatarImage,
                            title: staff.name,
                            subtitle: staff.designation.rawValue,
                            status: StatusBadge.from(staffStatus: staff.currentStatus)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .background(
                        cardTheme()
                    )
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private func performCancellation() {
        isCancelationDisabled = true
        trip.cancel()
        successMessage = "Trip \(trip.flightNumber) has been cancelled successfully."
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
            )
        ),
        RouteNode(
            plannedArrivalOffsetMinutes: 480,
            airport: Airport(
                code: "LHR",
                name: "London Heathrow",
                city: "London",
                country: "UK"
            )
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
