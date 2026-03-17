import Charts
import SwiftData
import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.modelContext) var context
    @Environment(SessionManager.self) var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query private var todayTrips: [Trip]
    @Query private var upcomingTrips: [Trip]
    @Query private var allStaff: [Staff]
    @Query private var allRoutes: [Route]

    @State private var activeSheet: ActiveSheet? = nil
    @State private var selectedTrip: Trip? = nil
    @State private var selectedStaff: Staff? = nil

    init() {
        _todayTrips = Query(
            filter: DashboardDB.todayTripsPredicate(),
            sort: \Trip.scheduledDepartureTime
        )
        _upcomingTrips = Query(
            filter: DashboardDB.upcomingTripsPredicate(withinHours: 6),
            sort: \Trip.scheduledDepartureTime
        )

        _allRoutes = Query(
            filter: #Predicate<Route> { $0.isActive }
        )
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            Group {
                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iOSLayout
                }
            }
            .navigationTitle("\(session.user?.name ?? "Admin")")
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                Group {
                    switch sheet {
                    case .upcomingTrips:
                        upcomingTripList

                    case .scheduledTrips, .completedTrips:
                        liveTripList(for: sheet)

                    case .activeRoutes:
                        activeRoutesList

                    case .selectedTripDetail(let trip):
                        TripDetailView(trip: trip)

                    case .selectedStaffDetail(let staff):
                        StaffDetailView(staff: staff)
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

    // MARK: - iPad
    var iPadLayout: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Row 1 — Stat cards (2 columns)
                tripDetailCards

                // Row 2 — Charts (2 columns, equal width)
                HStack(alignment: .top, spacing: 16) {
                    // Daily Trip Status
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
                    .frame(maxWidth: .infinity)

                    // Crew Status
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Crew Status")
                                .font(.headline)
                            Text("Availability of crew today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        DonutChartView(
                            data: crewStatusCounts,
                            defaultTitle: "Total staff"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .padding(16)
                    .background(cardTheme())
                    .frame(maxWidth: .infinity)
                }

                staffPerformanceSectionIpad

                // Upcoming Trips
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Upcoming Trips")
                                .font(.headline)
                            Text("Next 6 hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if filteredUpcomingTrip.count > 3 {
                            Button("View more") { activeSheet = .upcomingTrips }
                                .font(.subheadline)
                                .tint(Color(.systemBlue))
                        }
                    }
                    UpcomingTripsScrollView(
                        trips: filteredUpcomingTrip,
                        selectedTrip: $selectedTrip,
                        presentedSheet: $activeSheet,
                        onSelect: { item in
                            return .selectedTripDetail(trip: item)
                        }
                    )
                    .padding(.horizontal, -32)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 32)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: iOS
    var iOSLayout: some View {

        ScrollView {
            VStack(spacing: 20) {
                tripDetailCards

                VStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Daily Trip Status")
                            .font(.headline)
                        Text("Overview of operated trips today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    DonutChartView(
                        data: tripPerformanceSummary,
                        defaultTitle: "Total trips \noperated"
                    )
                    .frame(maxHeight: 500)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        cardTheme()
                    )
                }

                VStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Crew Status")
                            .font(.headline)
                        Text("Availability of crew today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    DonutChartView(
                        data: crewStatusCounts,
                        defaultTitle: "Total crew"
                    )
                    .frame(maxHeight: 500)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        cardTheme()
                    )
                }

                staffPerformanceSectionIos

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Upcoming Trips")
                                .font(.headline)
                            Text("Next 6 hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if filteredUpcomingTrip.count > 3 {
                            Spacer()
                            Button("View more") {
                                activeSheet = .upcomingTrips
                            }
                            .font(.subheadline)
                            .tint(Color(.systemBlue))
                        }
                    }

                    UpcomingTripsScrollView(
                        trips: filteredUpcomingTrip,
                        selectedTrip: $selectedTrip,
                        presentedSheet: $activeSheet,
                        onSelect: { item in
                            return .selectedTripDetail(trip: item)
                        }
                    )
                    .padding(.horizontal, -16)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
        }
        .refreshable {
            await DemoDataAPI.resolveExpiredTrips(in: context)
        }
        .scrollIndicators(.hidden)

    }
}

// MARK: Ui
extension AdminDashboardView {
    var upcomingTripList: some View {
        TripList(
            externalTrips: filteredUpcomingTrip,
            navigationTitle:
                "Trips in next 6 hours",
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
                ? "Completed Trips" : "Scheduled Trips",
            requiredFilters: []
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
    }

    var tripDetailCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
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
            }

            HStack(spacing: 12) {
                CardView(
                    title: "Active Routes",
                    value: "\(activeRoutesNowCount)",
                    subtitle: "Today",
                    icon: "point.topleft.down.curvedto.point.bottomright.up",
                    iconColor: Color(.systemTeal)
                )
                .onTapGesture {
                    if activeRoutesNowCount != 0 {
                        activeSheet = .activeRoutes
                    }
                }

                CardView(
                    title: "Route Utilisation",
                    value: routeUtilisationPercentLabel,
                    subtitle: "Today",
                    icon: "chart.pie.fill",
                    iconColor: Color(.systemIndigo)
                )
            }
        }
    }
}

// MARK: Active Routes
extension AdminDashboardView {
    var activeRoutesList: some View {
        List {
            ForEach(activeRoutesToday, id: \.id) { route in
                NavigationLink(destination: RouteDetailView(route: route)) {
                    ListRow(route: route)
                }
            }
        }
        .navigationTitle("Active Routes (\(activeRoutesNowCount))")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .listStyle(.insetGrouped)
        .tint(
            UIDevice.current.userInterfaceIdiom == .pad
                ? Color(.systemBlue).opacity(0.15) : Color.clear
        )
    }
}

// MARK: Staff Performance
extension AdminDashboardView {
    private func topPerformers(for role: StaffRole) -> [Staff] {
        allStaff
            .filter { $0.designation == role }
            .sorted { $0.totalTripHours > $1.totalTripHours }
            .prefix(3)
            .map { $0 }
    }

    var staffPerformanceSectionIpad: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Staff Performance")
                    .font(.headline)
                Text("Top performing staff")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                ForEach(StaffRole.allCases, id: \.self) { role in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(role.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(.label))

                        VStack(spacing: 8) {
                            ForEach(topPerformers(for: role), id: \.id) {
                                staff in
                                HStack {
                                    VStack {
                                        Button {
                                            selectedStaff = staff
                                            activeSheet = .selectedStaffDetail(
                                                staff: staff
                                            )
                                        } label: {
                                            ListRow(performanceStaff: staff)
                                        }
                                        .buttonStyle(.plain)

                                        if staff.id
                                            != topPerformers(for: role).last?.id
                                        {
                                            Divider()
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.smallCaps())
                                        .foregroundStyle(Color(.tertiaryLabel))
                                        .padding(.trailing, 12)
                                }
                            }

                        }
                    }
                    .padding(12)
                    .background(cardTheme())
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    var staffPerformanceSectionIos: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Staff Performance")
                    .font(.headline)
                Text("Top performing staff")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(StaffRole.allCases, id: \.self) { role in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(role.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(.label))

                        VStack(spacing: 8) {
                            ForEach(topPerformers(for: role), id: \.id) {
                                staff in
                                HStack {
                                    VStack {
                                        Button {
                                            selectedStaff = staff
                                            activeSheet = .selectedStaffDetail(
                                                staff: staff
                                            )
                                        } label: {
                                            ListRow(performanceStaff: staff)
                                        }
                                        .buttonStyle(.plain)

                                        if staff.id
                                            != topPerformers(for: role).last?.id
                                        {
                                            Divider()
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.smallCaps())
                                        .foregroundStyle(Color(.tertiaryLabel))
                                        .padding(.trailing, 12)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(cardTheme())
                }
            }
        }
    }
}

// MARK: Util
extension AdminDashboardView {
    private enum ActiveSheet: Identifiable, Equatable {
        case upcomingTrips
        case scheduledTrips
        case completedTrips
        case selectedTripDetail(trip: Trip)
        case activeRoutes
        case selectedStaffDetail(staff: Staff)

        var id: String {
            switch self {
            case .upcomingTrips: return "upcomingTrips"
            case .scheduledTrips: return "scheduledTrips"
            case .completedTrips: return "completedTrips"
            case .selectedTripDetail(let trip): return "trip_\(trip.id)"
            case .activeRoutes: return "activeRoutes"
            case .selectedStaffDetail(let staff): return "staff_\(staff.id)"
            }
        }
    }

    func formattedDouble(value: Double) -> String {
        let val = value

        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(val))
        } else {
            return String(format: "%.1f", val)
        }
    }
}

// MARK: - Data for display
extension AdminDashboardView {
    private func tripsToDisplay(for sheet: ActiveSheet) -> [Trip] {

        switch sheet {
        case .scheduledTrips:
            return todayTrips.filter { $0.currentStatus == .scheduled }

        case .completedTrips:
            return todayTrips.filter(\.isCompleted)

        default:
            return []
        }
    }

    private var filteredUpcomingTrip: [Trip] {
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

    private var crewStatusCounts: [(String, Int, Color)] {
        let now = Date()
        let until =
            Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now

        var available = 0
        var onDuty = 0
        var unavailable = 0

        for staff in allStaff {
            if staff.isMarkedUnavailable {
                unavailable += 1
            } else if staff.isAvailable(from: now, to: until) {
                available += 1
            } else {
                onDuty += 1
            }
        }

        return [
            (
                category: "Available", count: available,
                color: Color.staffStatusColor(for: .available)
            ),
            (
                category: "On Duty", count: onDuty,
                color: Color.staffStatusColor(for: .onDuty)
            ),
            (
                category: "Unavailable", count: unavailable,
                color: Color.staffStatusColor(for: .unavailable)
            ),
        ]
    }

    private var activeRoutesTodayCount: Int {
        Set(
            todayTrips
                .filter { !$0.isCancelled }
                .map { $0.route.id }
        ).count
    }

    private var activeRoutesToday: [Route] {

        let activeTripsNow = todayTrips.filter { trip in
            !trip.nodeStatuses.isEmpty || !trip.isCancelled
        }

        let unique = Dictionary(grouping: activeTripsNow.map(\.route)) { $0.id }
            .compactMap { $0.value.first }

        return unique.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private var activeRoutesNowCount: Int { activeRoutesToday.count }

    private var totalRoutesCount: Int {
        let routeIDs = Set(allRoutes.map(\.id))
        let operatingRouteIDs = Set(todayTrips.map { $0.route.id })
        let inActiveOperatingRouteCount = operatingRouteIDs.subtracting(
            routeIDs
        ).count
        return routeIDs.count + inActiveOperatingRouteCount
    }

    private var routeUtilisationPercentLabel: String {
        guard totalRoutesCount > 0 else { return "0%" }
        let pct =
            (Double(activeRoutesTodayCount) / Double(totalRoutesCount)) * 100.0
        return "\(formattedDouble(value: pct))%"
    }
}

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
