import Charts
import SwiftData
import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.modelContext) var context
    @Environment(SessionManager.self) var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query private var todayTrips: [Trip]
    @Query private var upcomingTrips: [Trip]
    @Query private var availableStaff: [Staff]
    @Query private var onDutyStaff: [Staff]
    @Query private var unavailableStaff: [Staff]

    @State private var activeSheet: ActiveSheet? = nil

    init() {
        _todayTrips = Query(
            filter: DashboardDB.todayTripsPredicate(),
            sort: \Trip.scheduledDepartureTime
        )
        _upcomingTrips = Query(
            filter: DashboardDB.upcomingTripsPredicate(withinHours: 6),
            sort: \Trip.scheduledDepartureTime
        )
        _availableStaff = Query(filter: DashboardDB.availableStaffPredicate)
        _onDutyStaff = Query(filter: DashboardDB.onDutyStaffPredicate)
        _unavailableStaff = Query(filter: DashboardDB.unavailableStaffPredicate)
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
                switch sheet {
                case .upcomingTrips:
                    upcomingTripList
                case .scheduledTrips, .completedTrips:
                    liveTripList(for: sheet)
                }
            }
        }
    }

    // MARK: - iPad Layout
    var iPadLayout: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Row 1 — Stat cards (2 columns)
                HStack(spacing: 16) {
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
                            Text("Overall crew availability")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        DonutChartView(
                            data: crewStatusCounts,
                            defaultTitle: "Total crew"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .padding(16)
                    .background(cardTheme())
                    .frame(maxWidth: .infinity)
                }

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
                    UpcomingTripsScrollView(trips: filteredUpcomingTrip)
                        .padding(.horizontal, -32)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 32)
        }
        .scrollIndicators(.hidden)
    }

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
                        Text("Overall crew availability")
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

                    UpcomingTripsScrollView(trips: filteredUpcomingTrip)
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
                "Trips in next 6 hours (\(filteredUpcomingTrip.count))",
            requiredFilters: [.scheduled, .cancelled]
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
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

    private func liveTripList(for sheet: ActiveSheet) -> some View {
        TripList(
            externalTrips: tripsToDisplay(for: sheet),
            navigationTitle:
                "",
            requiredFilters: []
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
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

    var tripDetailCards: some View {
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
    }
}

// MARK: Util
extension AdminDashboardView {
    private enum ActiveSheet: Identifiable {
        case upcomingTrips
        case scheduledTrips
        case completedTrips

        var id: Int { hashValue }
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
        return [
            (
                category: "Available", count: availableStaff.count,
                color: Color.staffStatusColor(for: .available)
            ),
            (
                category: "On Duty", count: onDutyStaff.count,
                color: Color.staffStatusColor(for: .onDuty)
            ),
            (
                category: "Unavailable", count: unavailableStaff.count,
                color: Color.staffStatusColor(for: .unavailable)
            ),
        ]
    }
}

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
