import SwiftData
import SwiftUI

struct RouteDetailView: View {
    var route: Route

    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.modelContext) var context

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
                    if isAdmin {
                        actionButton
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
    }
}

// MARK: UI
extension RouteDetailView {
    var actionButton: some View {
        Button {
            onTapAction()
        } label: {
            HStack(spacing: 8) {
                Image(
                    systemName: !route.isActive ? "mappin.and.ellipse" : "trash"
                )
                Text(!route.isActive ? "Restore route" : "Delete route")
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(!route.isActive ? Color(.systemGreen) : Color(.systemRed))
        .padding(.bottom, 8)
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

            let origin =
                route.nodes.first(where: { $0.sequence == 1 })?.airport.code
                ?? "_"
            let dest =
                route.nodes.last(where: { $0.sequence == route.nodes.count })?
                .airport.code
                ?? "_"
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
                    label: "Total trips",
                    value: "\(route.trips.count)"
                )
                DetailRowView(
                    label: "Scheduled trips",
                    value:
                        "\(route.trips.filter{$0.currentStatus == .scheduled}.count)"
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
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        HStack {
                            ListRow(trip: trip)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline.smallCaps())
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.trailing, 12)
                        }
                        .padding(12)
                    }
                    .buttonStyle(PressableRowStyle())

                    if trip.id != currentTrip.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                Color(.tertiarySystemBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
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
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .layoutPriority(1)

                            Text(node.airport.locationLabel)
                                .font(.subheadline)
                                .foregroundStyle(Color(.label))
                                .lineLimit(1)
                                .layoutPriority(1)

                            if index > 0 {
                                Text(
                                    "Arrival: \(node.plannedArrivalOffsetMinutes) min"
                                )
                                .font(.subheadline.bold())
                                .foregroundStyle(Color(.secondaryLabel))
                                .lineLimit(1)
                                .layoutPriority(1)
                            }
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

    var routeNameForNotification: String {
        if route.name.count > 20 {
            let firstWord = route.name.split(separator: " ").first ?? ""
            return String(
                firstWord.count <= 20
                    ? "\(firstWord)" : route.name.suffix(20).appending("...")
            )
        } else {
            return route.name
        }
    }

    func onTapAction() {
        let wasDeleted = route.isActive
        route.isActive.toggle()

        do {
            try context.save()
            notificationManager.showSuccess(
                "\(routeNameForNotification) is \(!wasDeleted ? "restored." : "deleted.")"
            )
        } catch {
            notificationManager.showError(
                "Failed to \(!wasDeleted ? "restore" : "delete") \(routeNameForNotification)."
            )
        }
    }

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

    var tripHistory: [Trip] {
        return route.trips.filter {
            $0.isCompleted == true || $0.isCancelled == true
        }.sorted(by: { $0.estimatedArrivalTime > $1.estimatedArrivalTime })
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
