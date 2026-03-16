import SwiftData
import SwiftUI

struct TripManagerDashboardView: View {
    @Environment(\.modelContext) var context

    @Query private var todayTrips: [Trip]
    @Query private var upcomingTrips: [Trip]

    @State private var activeSheet: ActiveSheet?

    init() {
        _todayTrips = Query(
            filter: DashboardDB.todayTripsPredicate(),
            sort: \Trip.scheduledDepartureTime
        )
        _upcomingTrips = Query(
            filter: DashboardDB.upcomingTripsPredicate(withinHours: 24),
            sort: \Trip.scheduledDepartureTime
        )
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    tripDetailCards

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
                                Spacer()
                                Button("View more") {
                                    activeSheet = .upcomingTrips
                                }
                                .font(.subheadline)
                                .tint(Color(.systemBlue))
                            }
                        }

                        UpcomingTripsScrollView(
                            trips: filteredUpcomingTrips,
                            noDataMessage: "No upcoming trips in next 24 hours"
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
            .sheet(item: $activeSheet) { sheet in
                NavigationStack {
                    switch sheet {
                    case .upcomingTrips:
                        upcomingTripList
                    case .onTimeTrips, .delayedTrips, .scheduledTrips,
                        .completedTrips:
                        liveTripList(for: sheet)
                    }
                }
            }
        }
    }
}

// MARK: - UI
extension TripManagerDashboardView {
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
                sheet == .completedTrips
            ? "Completed Trips" : sheet == .onTimeTrips ? "On-time Trips" : sheet == .delayedTrips ? "Delayed Trips" : "Scheduled Trips",
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
        VStack(spacing: 16) {
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
            HStack(spacing: 16) {
                CardView(
                    title: "On time Trips",
                    value: "\(liveOnTimeTripsCount)",
                    subtitle: "Operating now",
                    icon: "clock.badge.airplane",
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
                    icon: "clock.badge.airplane",
                    iconColor: Color.tripStatusColor(for: .delayed)
                )
                .onTapGesture {
                    if liveDelayedTripsCount != 0 {
                        activeSheet = .delayedTrips
                    }
                }
            }
        }

    }
}

// MARK: Util
extension TripManagerDashboardView {
    private enum ActiveSheet: Identifiable {
        case upcomingTrips
        case onTimeTrips
        case delayedTrips
        case scheduledTrips
        case completedTrips

        var id: Int { hashValue }
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
}

#Preview {
    TripManagerDashboardView()
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
}
