import SwiftData
import SwiftUI

struct TripDetailScreen: View {
    let trip: Trip

    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notification
    @Environment(\.dismiss) var dismiss

    @State private var isEditPresented = false

    var onCancelTapped: (() -> Void)? = nil

    var canCancelTrip: Bool {
        !trip.isCancelled && !trip.isCompleted && onCancelTapped != nil
    }

    var canEditTrip: Bool {
        trip.currentStatus == .scheduled
    }

    var tripHasStarted: Bool {
        !trip.nodeStatuses.isEmpty
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                detailView
            }
            .toolbar {
                if canEditTrip {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isEditPresented = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .sheet(isPresented: $isEditPresented) {
                NavigationStack {
                    TripRegistrationForm(
                        trip: trip,
                        isPresented: $isEditPresented
                    )
                }
            }
        }
    }

    var detailView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Section {
                        primaryCard
                    }

                    if canCancelTrip {
                        Section {
                            Button {
                                onCancelTapped?()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle")
                                        .font(.body.weight(.semibold))
                                    Text("Cancel Trip")
                                        .font(.body.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(.systemRed))
                        }
                    }

                    Section {
                        HStack(spacing: 12) {
                            CardView(
                                title: "Duration",
                                value:
                                    "\(trip.route.totalPlannedDurationMinutes) m",
                                icon: "clock",
                                iconColor: Color(.systemBrown)
                            )
                            CardView(
                                title: "Crew",
                                value: "\(trip.staffs.count)",
                                icon: "person.2",
                                iconColor: Color(.systemIndigo)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    proxy.scrollTo("staffSection", anchor: .top)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)

                    assignedAircraft
                        .padding(.bottom, 8)

                    if !trip.staffs.isEmpty {
                        assignedStaffList
                            .id("staffSection")
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 16)
    }

    var assignedAircraft: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Aircraft")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "airplane.cloud")
                    .font(.subheadline)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(Color(.systemBlue))
            }
            NavigationLink(
                destination: AircraftDetailView(
                    aircraft: trip.aircraft
                )
            ) {
                HStack {
                    ListRow(aircraft: trip.aircraft)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.smallCaps())
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.trailing, 12)
                }
                .padding(12)
            }
            .buttonStyle(PressableRowStyle())
        }
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemCyan))
                .padding(.bottom, 16)

            Text(trip.tripNumber)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            Text(trip.route.name)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.bottom, 12)

            StatusCapsuleView(
                statusBadge: StatusBadge.from(tripStatus: trip.currentStatus)
            )
            .padding(.bottom, 16)

            Divider()
                .opacity(0.75)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 10) {
                DetailRowView(
                    label: "Departure",
                    value: formatDate(
                        trip.scheduledDepartureTime,
                        format: "dd MMM yyyy, HH:mm"
                    )
                )
                DetailRowView(
                    label: "Arrival",
                    value: formatDate(
                        trip.estimatedArrivalTime,
                        format: "dd MMM yyyy, HH:mm"
                    )
                )
                if trip.currentStatus == .delayed {
                    DetailRowView(
                        label: "Delayed by",
                        value: "\(trip.totalDelayedMinutes) m"
                    )
                }

                let origin =
                    trip.route.nodes.first(where: { $0.sequence == 1 })?.airport
                    .code
                    ?? "_"
                let dest =
                    trip.route.nodes.last(where: {
                        $0.sequence == trip.route.nodes.count
                    })?
                    .airport.code
                    ?? "_"
                DetailRowView(label: "Route", value: "\(origin) → \(dest)")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardTheme())
    }

}

extension TripDetailScreen {

    @ViewBuilder
    var assignedStaffList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Flight Crew")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "person.2")
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemBlue))
            }

            VStack(spacing: 0) {
                ForEach(trip.staffs, id: \.id) { staff in

                    NavigationLink(
                        destination: StaffDetailView(staff: staff)
                    ) {
                        HStack {
                            ListRow(staff: staff)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline.smallCaps())
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.trailing, 12)
                        }
                        .padding(12)
                    }
                    if staff.id != trip.staffs.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .buttonStyle(PressableRowStyle())
            .background(
                Color(.tertiarySystemBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        }
        .padding(.bottom, 16)
    }
}
