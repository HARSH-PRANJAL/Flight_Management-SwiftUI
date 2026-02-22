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
            VStack(spacing: 16) {
                primaryCard

                if canCancelTrip {
                    cancelButton
                }

                HStack(spacing: 12) {
                    CardView(
                        title: "Duration",
                        value: "\(trip.route.totalPlannedDurationMinutes)m",
                        subtitle: "planned",
                        icon: "clock",
                        iconColor: Color(.white),
                        background: Color(.systemBlue)
                    )

                    CardView(
                        title: "Crew",
                        value: "\(trip.staffs.count)",
                        subtitle: "assigned",
                        icon: "person.2",
                        iconColor: Color(.white),
                        background: Color(.systemIndigo)
                    )
                }

                if trip.totalDelayedMinutes > 0 {
                    CardView(
                        title: "Delay",
                        value: String(
                            format: "%.1f",
                            Double(trip.route.totalPlannedDurationMinutes)
                                / 60.0
                        ).appending("hr"),
                        subtitle: "total",
                        icon: "exclamationmark.triangle",
                        iconColor: Color(.white),
                        background: Color(.systemOrange)
                    )
                }

                if !trip.staffs.isEmpty {
                    assignedStaffList
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
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

    var cancelButton: some View {
        ActionButton(
            style: .destructive,
            iconName: "xmark.circle",
            title: "Cancel Trip",
            action: { onCancelTapped?() }
        )
    }

    var assignedStaffList: some View {
        NavigationListSection(
            title: "Flight Crew",
            icon: "person.2",
            iconColor: Color(.systemBlue),
            items: trip.staffs,
            rowContent: { ListRow(staff: $0) },
            destination: { StaffDetailView(staff: $0) }
        )
    }
}

//#Preview {
//    NavigationStack {
//        let mockRoute = Route(name: "New York to London")
//        mockRoute.nodes = [
//            RouteNode(
//                plannedArrivalOffsetMinutes: 0,
//                airport: Airport(code: "JFK", name: "John F. Kennedy", city: "New York", country: "USA")
//            ),
//            RouteNode(
//                plannedArrivalOffsetMinutes: 480,
//                airport: Airport(code: "LHR", name: "London Heathrow", city: "London", country: "UK")
//            ),
//        ]
//
//        let mockAircraft = Aircraft(
//            registrationNumber: "N12345",
//            type: "Boeing 737",
//            seatingCapacity: 180,
//            minimumStaffRequired: [.pilot: 2, .cabinCrew: 4]
//        )
//
//        let mockStaff = Staff(
//            name: "John Doe",
//            designation: .pilot,
//            gender: .male,
//            email: "john@example.com",
//            dob: Date()
//        )
//
//        let mockTrip = Trip(
//            staff: [mockStaff],
//            aircraft: mockAircraft,
//            nodeStatuses: [],
//            route: mockRoute,
//            scheduledDepartureTime: Date().addingTimeInterval(3600),
//            flightNumber: "AA-100",
//            isCancelled: false
//        )
//
//        TripDetailScreen(
//            trip: mockTrip,
//            onCancelTapped: {}
//        )
//    }
//}
