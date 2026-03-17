import SwiftData
import SwiftUI

struct TripManagerDashboardView: View {
    @Environment(\.modelContext) var context

    @Query private var todayTrips: [Trip]
    @Query private var upcomingTrips: [Trip]
    @Query private var allAircraft: [Aircraft]
    @Query private var allTrips: [Trip]

    @State private var activeSheet: ActiveSheet?
    @State private var selectedTrip: Trip?
    @State private var selectedRoute: Route?

    init() {
        _todayTrips = Query(
            filter: DashboardDB.todayTripsPredicate(),
            sort: \Trip.scheduledDepartureTime
        )
        _upcomingTrips = Query(
            filter: DashboardDB.upcomingTripsPredicate(withinHours: 24),
            sort: \Trip.scheduledDepartureTime
        )

        _allAircraft = Query(
            filter: #Predicate<Aircraft> { !$0.isDecommissioned }
        )
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 24) {
                        cardsGrid(width: geo.size.width)
                        chartsGrid(width: geo.size.width)
                        routeAlertsSection(width: geo.size.width)
                        upcomingTripsSection(width: geo.size.width)
                        Spacer(minLength: 24)
                    }
                    .navigationTitle("Manager")
                }
                .padding(
                    .horizontal,
                    horizontalPadding(for: geo.size.width)
                )
                .refreshable {
                    await DemoDataAPI.resolveExpiredTrips(in: context)
                }
                .scrollIndicators(.hidden)
            }
            .sheet(item: $activeSheet) { sheet in
                NavigationStack {
                    Group {
                        switch sheet {
                        case .upcomingTrips:
                            upcomingTripList
                        case .onTimeTrips, .delayedTrips, .scheduledTrips,
                            .completedTrips:
                            liveTripList(for: sheet)
                        case .selectedTripDetail(let trip):
                            TripDetailView(trip: trip)
                        case .selectedRouteDetail(let route):
                            RouteDetailView(route: route)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                activeSheet = nil
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UI
extension TripManagerDashboardView {
    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width >= 700 ? 32 : 16
    }

    private func cardColumnCount(for width: CGFloat) -> Int {
        width >= 740 ? 4 : 2
    }

    private func cardColumns(for width: CGFloat) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 160), spacing: 12),
            count: cardColumnCount(for: width)
        )
    }

    private func chartColumns(for width: CGFloat) -> [GridItem] {
        let count = width >= 740 ? 2 : 1
        return Array(
            repeating: GridItem(.flexible(minimum: 320), spacing: 16),
            count: count
        )
    }

    @ViewBuilder
    func cardsGrid(width: CGFloat) -> some View {
        LazyVGrid(
            columns: cardColumns(for: width),
            alignment: .leading,
            spacing: 12
        ) {
            CardView(
                title: "Scheduled Trips",
                value: "\(scheduledTripsCount)",
                subtitle: "Today",
                icon: "clock.fill",
                iconColor: Color.tripStatusColor(for: .scheduled)
            )
            .onTapGesture {
                if scheduledTripsCount != 0 {
                    activeSheet = .scheduledTrips
                }
            }

            CardView(
                title: "Completed Trips",
                value: "\(completedTripsCount)",
                subtitle: "Today",
                icon: "airplane.arrival",
                iconColor: Color.tripStatusColor(for: .completed)
            )
            .onTapGesture {
                if completedTripsCount != 0 {
                    activeSheet = .completedTrips
                }
            }

            CardView(
                title: "On time Trips",
                value: "\(liveOnTimeTripsCount)",
                subtitle: "Operating now",
                icon: "clock.badge.airplane.fill",
                iconColor: Color.tripStatusColor(for: .onTime)
            )
            .onTapGesture {
                if liveOnTimeTripsCount != 0 {
                    activeSheet = .onTimeTrips
                }
            }

            CardView(
                title: "Delayed Trips",
                value: "\(liveDelayedTripsCount)",
                subtitle: "Operating now",
                icon: "clock.badge.airplane.fill",
                iconColor: Color.tripStatusColor(for: .delayed)
            )
            .onTapGesture {
                if liveDelayedTripsCount != 0 {
                    activeSheet = .delayedTrips
                }
            }
        }
    }

    @ViewBuilder
    func chartsGrid(width: CGFloat) -> some View {
        LazyVGrid(
            columns: chartColumns(for: width),
            alignment: .leading,
            spacing: 16
        ) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Trip Status")
                        .font(.headline)
                    Text("Overview of operated trips today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                DonutChartView(
                    data: tripPerformanceSummary,
                    defaultTitle: "Total trips \noperated"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .padding(16)
            .background(cardTheme())

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aircraft Utilization")
                        .font(.headline)
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                DonutChartView(
                    data: aircraftUtilisationCounts,
                    defaultTitle: "Total aircraft"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .padding(16)
            .background(cardTheme())
        }
    }

    @ViewBuilder
    func routeAlertsSection(width: CGFloat) -> some View {
        if width >= 760 {
            routeAlertsSectionIpad
        } else {
            routeAlertsSectionIos
        }
    }

    @ViewBuilder
    func upcomingTripsSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Upcoming Trips")
                        .font(.headline)
                    Text("Next 24 hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if filteredUpcomingTrips.count > 3 {
                    Button("View more") {
                        activeSheet = .upcomingTrips
                    }
                    .font(.subheadline)
                    .tint(Color(.systemBlue))
                }
            }

            UpcomingTripsScrollView(
                trips: filteredUpcomingTrips,
                noDataMessage: "No upcoming trips in next 24 hours",
                selectedTrip: $selectedTrip,
                presentedSheet: $activeSheet,
                onSelect: { item in
                    return .selectedTripDetail(trip: item)
                }
            )
            .padding(.horizontal, -horizontalPadding(for: width))
        }
    }

    var upcomingTripList: some View {
        TripList(
            externalTrips: filteredUpcomingTrips,
            navigationTitle:
                "Trips in next 24 hr",
            requiredFilters: [.scheduled, .cancelled],
            statusBadgeRequired: true
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
    }

    private func liveTripList(for sheet: ActiveSheet) -> some View {
        TripList(
            externalTrips: tripsToDisplay(for: sheet),
            navigationTitle:
                sheet == .completedTrips
                ? "Completed Trips"
                : sheet == .onTimeTrips
                    ? "On-time Trips"
                    : sheet == .delayedTrips
                        ? "Delayed Trips" : "Scheduled Trips",
            requiredFilters: []
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
    }

    var routeAlertsSectionIpad: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Route Alerts")
                    .font(.headline)
                Text("Overall trip operated in routes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                CardView(
                    title: "Most Delayed Route",
                    value: mostDelayedRouteName,
                    subtitle: mostDelayedRouteSubtitle,
                    icon: "clock.arrow.circlepath.fill",
                    iconColor: Color.tripStatusColor(for: .delayed)
                )
                .onTapGesture {
                    if let route = mostDelayedRoute {
                        selectedRoute = route
                        activeSheet = .selectedRouteDetail(route: route)
                    }
                }

                CardView(
                    title: "Most Cancelled Route",
                    value: mostCancelledRouteName,
                    subtitle: mostCancelledRouteSubtitle,
                    icon: "xmark.octagon.fill",
                    iconColor: Color.tripStatusColor(for: .cancelled)
                )
                .onTapGesture {
                    if let route = mostCancelledRoute {
                        selectedRoute = route
                        activeSheet = .selectedRouteDetail(route: route)
                    }
                }
            }
        }
    }

    var routeAlertsSectionIos: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Route Alerts")
                    .font(.headline)

                Text("Overall trip operated in routes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                CardView(
                    title: "Most Delayed Route",
                    value: mostCancelledRouteName,
                    subtitle: mostDelayedRouteSubtitle,
                    icon: "clock.arrow.circlepath",
                    iconColor: Color.tripStatusColor(for: .delayed)
                )
                .onTapGesture {
                    if let route = mostDelayedRoute {
                        selectedRoute = route
                        activeSheet = .selectedRouteDetail(route: route)
                    }
                }

                CardView(
                    title: "Most Cancelled Route",
                    value: mostCancelledRouteName,
                    subtitle: mostCancelledRouteSubtitle,
                    icon: "xmark.octagon.fill",
                    iconColor: Color.tripStatusColor(for: .cancelled)
                )
                .onTapGesture {
                    if let route = mostCancelledRoute {
                        selectedRoute = route
                        activeSheet = .selectedRouteDetail(route: route)
                    }
                }
            }
        }
    }
}

// MARK: Util
extension TripManagerDashboardView {
    private enum ActiveSheet: Identifiable, Equatable {
        case upcomingTrips
        case onTimeTrips
        case delayedTrips
        case scheduledTrips
        case completedTrips
        case selectedTripDetail(trip: Trip)
        case selectedRouteDetail(route: Route)

        var id: String {
            switch self {
            case .upcomingTrips: return "upcomingTrips"
            case .scheduledTrips: return "scheduledTrips"
            case .completedTrips: return "completedTrips"
            case .onTimeTrips: return "onTimeTrips"
            case .delayedTrips: return "delayedTrips"
            case .selectedTripDetail(let trip): return "trip_\(trip.id)"
            case .selectedRouteDetail(let route): return "route_\(route.id)"
            }
        }
    }
}

// MARK: Data for display
extension TripManagerDashboardView {
    private func tripsToDisplay(for sheet: ActiveSheet) -> [Trip] {

        switch sheet {
        case .delayedTrips:
            return todayTrips.filter { $0.currentStatus == .delayed }

        case .onTimeTrips:
            return todayTrips.filter { $0.currentStatus == .onTime }

        case .scheduledTrips:
            return todayTrips.filter { $0.currentStatus == .scheduled }

        case .completedTrips:
            return todayTrips.filter(\.isCompleted)

        default:
            return []
        }
    }

    private var filteredUpcomingTrips: [Trip] {
        return upcomingTrips.filter {
            $0.currentStatus == .scheduled || $0.currentStatus == .cancelled
        }
    }

    var scheduledTripsCount: Int {
        return todayTrips.filter { $0.currentStatus == .scheduled }.count
    }

    var completedTripsCount: Int {
        return todayTrips.filter { $0.isCompleted }.count
    }

    var liveOnTimeTripsCount: Int {
        return todayTrips.filter { $0.currentStatus == .onTime }.count
    }

    var liveDelayedTripsCount: Int {
        return todayTrips.filter { $0.currentStatus == .delayed }.count
    }

    var tripPerformanceSummary: [(String, Int, Color)] {
        let completedTrips = todayTrips.filter(\.isCompleted)
        let onTime = completedTrips.filter {
            $0.totalDelayedMinutes == 0
        }.count
        let delayed = completedTrips.filter {
            $0.totalDelayedMinutes > 0
        }.count
        let cancelled = todayTrips.filter { $0.isCancelled }.count

        return [
            ("On-Time", onTime, Color.tripStatusColor(for: .onTime)),
            ("Delayed", delayed, Color.tripStatusColor(for: .delayed)),
            ("Cancelled", cancelled, Color.tripStatusColor(for: .cancelled)),
        ].filter { $0.1 > 0 }
    }

    private var aircraftUtilisationCounts: [(String, Int, Color)] {
        let operatingAircraftIDs = Set(
            todayTrips
                .filter { !$0.isCancelled }
                .map { $0.aircraft.id }
        )

        let activeFleet = allAircraft.filter { !$0.isDecommissioned }
        let onDuty = activeFleet.filter { operatingAircraftIDs.contains($0.id) }
            .count
        let available = max(0, activeFleet.count - onDuty)

        return [
            (
                category: "Available",
                count: available,
                color: Color.aircraftStatusColor(for: .available)
            ),
            (
                category: "On Duty",
                count: onDuty,
                color: Color.aircraftStatusColor(for: .assigned)
            ),
        ]
    }

    private var delayedTripCountsByRoute: [(route: Route, delayedCount: Int)] {
        let now = Date()
        let tripsSoFar = allTrips.filter { $0.scheduledDepartureTime <= now }
        let grouped = Dictionary(grouping: tripsSoFar) { $0.route.id }
        let byRoute: [(Route, Int)] = grouped.compactMap { _, trips in
            guard let route = trips.first?.route else { return nil }
            let delayedCount = trips.filter { $0.totalDelayedMinutes > 0 }.count
            return (route, delayedCount)
        }
        return byRoute.sorted { $0.1 > $1.1 }
    }

    private var cancelledTripCountsByRoute:
        [(route: Route, cancelledCount: Int)]
    {
        let now = Date()
        let tripsSoFar = allTrips.filter { $0.scheduledDepartureTime <= now }
        let grouped = Dictionary(grouping: tripsSoFar) { $0.route.id }
        let byRoute: [(Route, Int)] = grouped.compactMap { _, trips in
            guard let route = trips.first?.route else { return nil }
            let cancelledCount = trips.filter(\.isCancelled).count
            return (route, cancelledCount)
        }
        return byRoute.sorted { $0.1 > $1.1 }
    }

    private var mostDelayedRoute: Route? {
        delayedTripCountsByRoute.first(where: { $0.delayedCount > 0 })?.route
    }

    private var mostCancelledRoute: Route? {
        cancelledTripCountsByRoute.first(where: { $0.cancelledCount > 0 })?
            .route
    }

    private var mostDelayedRouteName: String {
        mostDelayedRoute?.name ?? "—"
    }

    private var mostCancelledRouteName: String {
        mostCancelledRoute?.name ?? "—"
    }

    private var mostDelayedRouteSubtitle: String? {
        guard let top = delayedTripCountsByRoute.first, top.delayedCount > 0
        else {
            return "No delayed trips"
        }
        return "\(top.delayedCount) delayed trips"
    }

    private var mostCancelledRouteSubtitle: String? {
        guard let top = cancelledTripCountsByRoute.first, top.cancelledCount > 0
        else {
            return "No cancelled trips"
        }
        return "\(top.cancelledCount) cancelled trips"
    }
}

#Preview {
    TripManagerDashboardView()
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
}
