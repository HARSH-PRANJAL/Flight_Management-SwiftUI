import Charts
import SwiftData
import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.modelContext) var context
    @Environment(SessionManager.self) var session

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
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 24) {
                        cardsGrid(width: geo.size.width)
                        chartsGrid(width: geo.size.width)
                        staffPerformanceSection(width: geo.size.width)
                        upcomingTripsSection(width: geo.size.width)
                        Spacer(minLength: 24)
                    }
                    .navigationTitle("Admin")
                }
                .padding(.horizontal, horizontalPadding(for: geo.size.width))
                .refreshable {
                    await DemoDataAPI.resolveExpiredTrips(in: context)
                }
                .scrollIndicators(.hidden)
            }
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
}

// MARK: Ui
extension AdminDashboardView {
    // MARK: Responsive layout helpers (Grid-based)
    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width >= 700 ? 32 : 16
    }

    private func cardColumnCount(for width: CGFloat) -> Int {
        // Target layout:
        // - iPad (wider): 4 cards per row
        // - iPhone / narrow: 2 cards per row
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
        return Array(repeating: GridItem(.flexible(minimum: 320), spacing: 16), count: count)
    }

    @ViewBuilder
    func cardsGrid(width: CGFloat) -> some View {
        LazyVGrid(columns: cardColumns(for: width), alignment: .leading, spacing: 12) {
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
                iconColor: Color(.systemIndigo),
                clickable: false
            )
        }
    }

    @ViewBuilder
    func chartsGrid(width: CGFloat) -> some View {
        LazyVGrid(columns: chartColumns(for: width), alignment: .leading, spacing: 16) {
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
        }
    }

    @ViewBuilder
    func staffPerformanceSection(width: CGFloat) -> some View {
        // Wider layouts get the 3-column role layout, otherwise stacked.
        if cardColumnCount(for: width) == 4 {
            staffPerformanceSectionIpad
        } else {
            staffPerformanceSectionIos
        }
    }

    @ViewBuilder
    func upcomingTripsSection(width: CGFloat) -> some View {
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
            .padding(.horizontal, -horizontalPadding(for: width))
        }
    }

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
        let top3 = allStaff
            .filter { $0.designation == role }
            .sorted {
                if $0.totalTripHours != $1.totalTripHours {
                    return $0.totalTripHours > $1.totalTripHours
                }
                return $0.trips.count > $1.trips.count
            }
            .prefix(3)
            .map { $0 }

        // If the best 3 performers have 0 hours, treat as no data.
        if !top3.isEmpty && top3.allSatisfy({ $0.totalTripHours == 0 }) {
            return []
        }

        return top3
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
                    let performers = topPerformers(for: role)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(role.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(.label))

                        VStack(spacing: 8) {
                            if performers.isEmpty {
                                ContentUnavailableView(
                                    "No performance data",
                                    systemImage: "chart.bar"
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            } else {
                                ForEach(performers, id: \.id) { staff in
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

                                            if staff.id != performers.last?.id {
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
                    let performers = topPerformers(for: role)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(role.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(.label))

                        VStack(spacing: 8) {
                            if performers.isEmpty {
                                ContentUnavailableView(
                                    "No performance data",
                                    systemImage: "chart.bar"
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            } else {
                                ForEach(performers, id: \.id) { staff in
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

                                            if staff.id != performers.last?.id {
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
