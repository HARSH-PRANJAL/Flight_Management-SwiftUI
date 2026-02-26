import SwiftData
import SwiftUI

struct TripDetailScreen: View {
    let trip: Trip

    var onCancelTapped: (() -> Void)? = nil
    var canCancelTrip: Bool {
        !trip.isCancelled && !trip.isCompleted && onCancelTapped != nil
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                detailView
            }
        }
    }

    var detailView: some View {
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
                            subtitle: "planned",
                            icon: "clock",
                            iconColor: Color(.systemBrown)
                        )
                        CardView(
                            title: "Crew",
                            value: "\(trip.staffs.count)",
                            subtitle: "assigned",
                            icon: "person.2",
                            iconColor: Color(.systemIndigo)
                        )
                    }
                }
                .padding(.bottom, 8)

                ClickableSection(
                    title: "Assigned Aircraft",
                    icon: "airplane",
                    iconColor: Color(.systemBlue),
                    row: { ListRow(aircraft: trip.aircraft) },
                    destination: { AircraftDetailView(aircraft: trip.aircraft) }
                )
                .padding(.bottom, 8)

                if !trip.staffs.isEmpty {
                    assignedStaffList
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 16)
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemCyan))
                .padding(.bottom, 16)

            Text(trip.flightNumber)
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
                    label: "Aircraft",
                    value:
                        "\(trip.aircraft.type) (\(trip.aircraft.registrationNumber))"
                )
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

                let origin = trip.route.nodes.first?.airport.code ?? "—"
                let dest = trip.route.nodes.last?.airport.code ?? "—"
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
