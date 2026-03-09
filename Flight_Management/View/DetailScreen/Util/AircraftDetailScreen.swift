import SwiftData
import SwiftUI

struct AircraftDetailScreen: View {

    @Environment(\.modelContext) var context
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.dismiss) var dismiss

    let aircraft: Aircraft
    var isManager: Bool = false
    var isAircraftAvailable: Bool { aircraft.currentStatus == .available }

    @State private var selectedTab: DetailTab = .detail
    @State private var scheduledTrips: [Trip] = []
    @Binding var isEditPagePresented: Bool
    @Binding var isScheduledTripsPresented: Bool
    @State private var showDecommissionAlert: Bool = false

    var tripHours: String {
        let hours = aircraft.totalTripHours

        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(hours))
        } else {
            return String(format: "%.1f", hours)
        }
    }

    var tripString: String {
        if scheduledTrips.count > 1 {
            return "trips"
        } else {
            return "trip"
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if aircraft.trips.isEmpty {
                    detailView
                } else {
                    switch selectedTab {
                    case .detail:
                        detailView
                    case .tripHistory:
                        tripHistoryContent
                    }
                }
            }
            .navigationTitle(aircraft.registrationNumber)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !aircraft.trips.isEmpty {
                        detailScreenPicker(selectedTab: $selectedTab)
                    } else {
                        Button(""){}
                    }
                }
            }
            .alert("", isPresented: $showDecommissionAlert) {

                Button("Decommission", role: .destructive) {
                    decommissionAircraft()
                    dismiss()
                }

                Button("Cancel", role: .cancel) {}

            } message: {
                if scheduledTrips.count > 0 {
                    Text(
                        """
                        Decommissioning will result in the immediate cancellation of \(scheduledTrips.count) upcoming \(tripString). 

                        Once decommissioned, it will be permanently removed from service.
                        """
                    )
                    .multilineTextAlignment(.leading)
                } else {
                    Text(
                        """
                        Are you sure you want to decommission this aircraft?

                        Once decommissioned, it will be permanently removed from service.
                        """
                    )
                    .multilineTextAlignment(.leading)
                }
            }
        }
        .animation(.linear(duration: 0.5), value: selectedTab)
        .onAppear {
            if scheduledTrips.isEmpty {
                scheduledTrips = aircraft.scheduledTrips
            }
        }
    }
}

// MARK: UI
extension AircraftDetailScreen {

    var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Section {
                    primaryCard
                }

                Section {
                    HStack(spacing: 12) {
                        CardView(
                            title: "Scheduled",
                            value: "\(aircraft.scheduledTrips.count)",
                            icon: "calendar",
                            iconColor: Color(.systemIndigo)
                        )
                        .onTapGesture {
                            if !aircraft.scheduledTrips.isEmpty {
                                isScheduledTripsPresented.toggle()
                            }
                        }
                        CardView(
                            title: "Flying Hours",
                            value: "\(tripHours) hr",
                            icon: "clock",
                            iconColor: Color(.systemBrown)
                        )
                    }
                }

                tripSectionCards
            }
            .padding([.horizontal, .top], 16)
        }
        .scrollIndicators(.hidden)
        .toolbar {
            if isManager && isAircraftAvailable && !aircraft.isDecommissioned {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarMenu
                }
            }
        }
    }

    var tripHistoryContent: some View {
        TripList(
            externalTrips: aircraft.trips,
            navigationTitle: "\(aircraft.registrationNumber) trips",
            requiredFilters: [.scheduled, .cancelled, .completed],
            isCountRequired: true
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
    }

    var tripSectionCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let trip = aircraft.currentTrip {
                ClickableSection(
                    title: "Current Trip",
                    icon: "clock.badge.airplane",
                    iconColor: Color(.systemCyan),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
            if let trip = aircraft.nextScheduledTrip {
                ClickableSection(
                    title: "Next Trip",
                    icon: "calendar.badge.clock",
                    iconColor: Color(.systemIndigo),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
            if let trip = aircraft.lastCompletedTrip {
                ClickableSection(
                    title: "Last Trip",
                    icon: "checkmark.circle",
                    iconColor: Color(.systemGreen),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
        }
        .padding(.bottom, 16)
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "airplane")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemBlue))
                .padding(.bottom, 16)

            Text(aircraft.registrationNumber)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            Text(aircraft.type)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.bottom, 12)

            StatusCapsuleView(
                statusBadge: StatusBadge.from(
                    aircraftStatus: aircraft.currentStatus
                )
            )
            .padding(.bottom, 16)

            Divider()
                .opacity(0.75)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 10) {
                DetailRowView(
                    label: "Total trips",
                    value: "\(aircraft.trips.count)"
                )
                DetailRowView(
                    label: "Seating capacity",
                    value: "\(aircraft.seatingCapacity)"
                )
                .padding(.bottom, 12)

                Divider()
                    .opacity(0.75)
                    .padding(.bottom, 12)

                Text("Minimum Staff Required for operation")
                    .foregroundStyle(Color.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                DetailRowView(
                    label: "Pilot",
                    value: "\(aircraft.minimumStaffRequired[.pilot] ?? 0)"
                )
                DetailRowView(
                    label: "Co-Pilot",
                    value: "\(aircraft.minimumStaffRequired[.coPilot] ?? 0)"
                )
                DetailRowView(
                    label: "Cabin Crew",
                    value: "\(aircraft.minimumStaffRequired[.cabinCrew] ?? 0)"
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardTheme())
    }

    var toolbarMenu: some View {
        Menu {
            Button {
                isEditPagePresented = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                showDecommissionAlert = true
            } label: {
                Label("Decommission", systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}

// MARK: Util
extension AircraftDetailScreen {
    private func decommissionAircraft() {
        cancelAllScheduledTripsWithCurrentTrip()
        aircraft.isDecommissioned = true

        do {
            try context.save()
            notificationManager.showSuccess(
                "\(aircraft.registrationNumber) has been decommissioned."
            )
        } catch {
            notificationManager.showSuccess(
                "Failed to be decommission. Please try again."
            )
        }
    }

    private func cancelAllScheduledTripsWithCurrentTrip() {
        for trip in scheduledTrips {
            trip.cancel()
        }
    }
}
