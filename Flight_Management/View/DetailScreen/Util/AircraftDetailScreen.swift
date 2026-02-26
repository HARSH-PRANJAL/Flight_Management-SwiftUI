import SwiftData
import SwiftUI

struct AircraftDetailScreen: View {
    let aircraft: Aircraft
    var isManager: Bool = false
    var isAircraftAvailable: Bool { aircraft.currentStatus == .available }

    @State private var selectedTab: DetailTab = .detail
    @Binding var isEditPagePresented: Bool

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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !aircraft.trips.isEmpty {
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
                            subtitle: "trips",
                            icon: "calendar",
                            iconColor: Color(.systemIndigo)
                        )
                        CardView(
                            title: "Flying Hours",
                            value: String(
                                format: "%.1f",
                                aircraft.totalTripHours
                            ),
                            subtitle: "  ",
                            icon: "clock",
                            iconColor: Color(.systemBrown)
                        )
                    }
                }

                tripSectionCards
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    var tripHistoryContent: some View {
        TripListView(externalTrips: aircraft.trips, navigationTitle: "")
    }
}

// MARK: UI
extension AircraftDetailScreen {

    var tripSectionCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let trip = aircraft.currentTrip {
                ClickableSection(
                    title: "Current Flight",
                    icon: "clock.badge.airplane",
                    iconColor: Color(.systemCyan),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
            if let trip = aircraft.nextScheduledTrip {
                ClickableSection(
                    title: "Next Flight",
                    icon: "calendar.badge.clock",
                    iconColor: Color(.systemIndigo),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
            if let trip = aircraft.lastCompletedTrip {
                ClickableSection(
                    title: "Last Flight",
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
