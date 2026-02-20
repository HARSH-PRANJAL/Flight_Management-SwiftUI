import SwiftUI

struct RouteDetailView: View {
    let route: Route

    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager

    @State private var isEditPageShowing: Bool = false

    var isAdmin: Bool {
        session.user?.role == UserRole.admin.rawValue
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    primaryCard

                    HStack(spacing: 12) {
                        CardView(
                            title: "Total Trips",
                            value: "\(route.trips.count)",
                            subtitle: "",
                            icon: "airplane.up.right",
                            iconColor: Color(.white),
                            background: Color(.systemBlue)
                        )

                        CardView(
                            title: "Scheduled Trips",
                            value: "\(countScheduleTrips)",
                            subtitle: "",
                            icon: "calendar",
                            iconColor: Color(.white),
                            background: Color(.systemIndigo)
                        )
                    }

                    airportNodesCard

                    if !currentTrip.isEmpty {
                        currentTripsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isEditPageShowing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditPageShowing) {
            NavigationStack {
                RouteRegistrationForm(
                    route: route,
                    isPresented: $isEditPageShowing
                )
            }
        }
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Image(
                systemName:
                    "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath"
            )
            .font(.system(size: 48))
            .foregroundStyle(Color(.systemPurple))
            .padding(.bottom, 16)

            Text(route.name)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            let origin = route.nodes.first?.airport.code ?? "—"
            let dest = route.nodes.last?.airport.code ?? "—"
            Text("\(origin) → \(dest)")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.bottom, 12)

            Divider()
                .opacity(0.75)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 10) {
                DetailRowView(label: "Airports", value: "\(route.nodes.count)")
                DetailRowView(
                    label: "Duration",
                    value: "\(route.totalPlannedDurationMinutes) min"
                )
                DetailRowView(
                    label: "Total Trips",
                    value: "\(route.trips.count)"
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardTheme())
    }

    var currentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Current Trips")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: "clock.badge.airplane")
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemCyan))
            }

            VStack(spacing: 0) {
                ForEach(currentTrip, id: \.id) { trip in
                    HStack {
                        NavigationLink(destination: TripDetailView(trip: trip))
                        {
                            ListRow(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.smallCaps())
                            .foregroundStyle(Color(.tertiaryLabel))
                            .padding(.trailing, 12)
                    }

                    if trip.id != currentTrip.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(cardTheme())
        }
        .padding(.bottom, 16)
    }

    var airportNodesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Route Stops")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: "mappin.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemOrange))
            }

            VStack(spacing: 0) {
                ForEach(
                    Array(sequencedRouteNodes.enumerated()),
                    id: \.element.id
                ) {
                    index,
                    node in
                    HStack(alignment: .center, spacing: 12) {
                        Text("\(index+1).")
                            .font(.callout)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(node.airport.fullName)
                                .font(.headline)
                                .foregroundStyle(Color(.label))
                                .multilineTextAlignment(.leading)
                                .layoutPriority(1)

                            Text(node.airport.locationLabel)
                                .font(.subheadline)
                                .foregroundStyle(Color(.label))
                                .lineLimit(1)
                                .layoutPriority(1)

                            Text(
                                "Arrival: \(node.plannedArrivalOffsetMinutes) min"
                            )
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(1)
                            .layoutPriority(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    if index < sequencedRouteNodes.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(cardTheme())
        }
        .padding(.bottom, 16)
    }
}

// MARK: Util
extension RouteDetailView {

    var sequencedRouteNodes: [RouteNode] {
        return route.nodes.sorted(by: { $0.sequence < $1.sequence })
    }

    var countScheduleTrips: Int {
        return route.trips.filter { $0.currentStatus == .scheduled }.count
    }

    var currentTrip: [Trip] {
        return route.trips.filter {
            $0.currentStatus == .onTime || $0.currentStatus == .delayed
        }.sorted(by: { $0.scheduledDepartureTime < $1.scheduledDepartureTime })
    }
}

#Preview {
    NavigationStack {
        RouteDetailView(
            route: Route(
                name: "London to New York"
            )
        )
    }
}
