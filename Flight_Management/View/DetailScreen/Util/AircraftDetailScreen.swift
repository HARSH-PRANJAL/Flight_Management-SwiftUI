import SwiftData
import SwiftUI

struct AircraftDetailScreen: View {
    let aircraft: Aircraft
    var isManager: Bool = false
    var isAircraftAvailable: Bool { aircraft.currentStatus == .available }

    @State private var selectedTab: DetailTab = .detail
    @Binding var isEditPagePresented: Bool

    var hasTripHistory: Bool {
        !aircraft.trips.isEmpty
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if !hasTripHistory {
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if hasTripHistory {
                        detailScreenPicker(selectedTab: $selectedTab)
                    }
                }

                if isManager && isAircraftAvailable {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { isEditPagePresented = true }) {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal > 100 {
                            selectedTab = .detail
                        }
                        if horizontal < -100 {
                            selectedTab = .tripHistory
                        }
                    }
            )
        }
        .animation(.linear(duration: 0.5), value: selectedTab)
    }

    var detailView: some View {
        List {
            Section {
                primaryCard
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(cardTheme())
            .listRowSeparator(.hidden)

            Section {
                HStack(spacing: 12) {
                    CardView(
                        title: "Total Trips",
                        value: "\(aircraft.totalTripsOperated)",
                        subtitle: "",
                        icon: "airplane.up.right",
                        iconColor: Color(.white),
                        background: Color(.systemBlue)
                    )
                    CardView(
                        title: "Flight Hours",
                        value: String(format: "%.1f", aircraft.totalTripHour),
                        subtitle: "",
                        icon: "clock",
                        iconColor: Color(.white),
                        background: Color(.systemRed)
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                HStack(spacing: 12) {
                    CardView(
                        title: "Seating",
                        value: "\(aircraft.seatingCapacity)",
                        subtitle: "capacity",
                        icon: "person.3",
                        iconColor: Color(.white),
                        background: Color(.systemGreen)
                    )
                    CardView(
                        title: "Scheduled",
                        value: "\(aircraft.scheduledTrips.count)",
                        subtitle: "trips",
                        icon: "calendar",
                        iconColor: Color(.white),
                        background: Color(.systemIndigo)
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if let trip = aircraft.currentTrip {
                Section {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        ListRow(trip: trip)
                    }
                } header: {
                    Label("Current Trip", systemImage: "airplane.departure")
                        .foregroundStyle(Color(.systemCyan))
                }
            }

            if let trip = aircraft.nextScheduledTrip {
                Section {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        ListRow(trip: trip)
                    }
                } header: {
                    Label("Next Trip", systemImage: "calendar.badge.clock")
                        .foregroundStyle(Color(.systemIndigo))
                }
            }

            if let trip = aircraft.lastCompletedTrip {
                Section {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        ListRow(trip: trip)
                    }
                } header: {
                    Label("Last Trip", systemImage: "checkmark.circle")
                        .foregroundStyle(Color(.systemGreen))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    var tripHistoryContent: some View {
        TripListView(externalTrips: aircraft.trips, navigationTitle: "")
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
                    label: "Seating Capacity",
                    value: "\(aircraft.seatingCapacity) seats"
                )

                let staffReq = aircraft.minimumStaffRequired.map {
                    "\($0.key.rawValue): \($0.value)"
                }.joined(separator: ", ")
                DetailRowView(
                    label: "Min Staff Required",
                    value: staffReq.isEmpty ? "None" : staffReq
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardTheme())
    }
}

#Preview {
    NavigationStack {
        AircraftDetailScreen(
            aircraft: Aircraft(
                registrationNumber: "N12345",
                type: "Boeing 737",
                seatingCapacity: 180,
                minimumStaffRequired: [.pilot: 2, .cabinCrew: 4]
            ),
            isEditPagePresented: .constant(false)
        )
    }
}

