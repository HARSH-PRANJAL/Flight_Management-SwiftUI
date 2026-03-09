import SwiftData
import SwiftUI

struct TripManagerDashboardView: View {
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager

    @Query private var todayTrips: [Trip]
    @Query private var upcomingTrips: [Trip]

    @State var showingTripList: Bool = false

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
                        Text("Overview of all trips today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    DonutChartView(
                        data: tripsSummary,
                        defaultTitle: "Total trips"
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
                                    showingTripList = true
                                }
                                .font(.subheadline)
                                .tint(Color(.systemBlue))
                            }
                        }

                        UpcomingTripsScrollView(trips: filteredUpcomingTrips, noDataMessage: "No upcoming trips in next 24 hours")
                            .padding(.horizontal, -16)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $showingTripList) {
                NavigationStack {
                    TripList(
                        externalTrips: filteredUpcomingTrips,
                        navigationTitle:
                            "Trips in next 24 hr (\(filteredUpcomingTrips.count))",
                        requiredFilters: [.scheduled, .cancelled]
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .padding(.top, -20)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                showingTripList = false
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

    var tripDetailCards: some View {
        HStack(spacing: 12) {
            CardView(
                title: "On-Time Performance",
                value: "\(onTimePercentage)%",
                subtitle: "Trips today",
                icon: "clock.fill",
                iconColor: Color(.systemGreen).opacity(0.75)
            )

            CardView(
                title: "Delayed Trips",
                value: "\(delayedCount)",
                subtitle: "Today",
                icon: "airplane.departure",
                iconColor: Color(.systemRed).opacity(0.75)
            )
        }
    }
}

// MARK: - Data for display
extension TripManagerDashboardView {

    private var filteredUpcomingTrips: [Trip] {
        return upcomingTrips.filter {
            $0.currentStatus == .scheduled || $0.currentStatus == .cancelled
        }
    }

    private var onTimePercentage: Int {
        let total = todayTrips.filter {
            $0.currentStatus == .onTime || $0.currentStatus == .delayed
        }.count
        if total <= 0 { return 0 }
        let onTime = todayTrips.filter { $0.currentStatus == .onTime }.count
        return Int((Double(onTime) / Double(total)) * 100)
    }

    private var delayedCount: Int {
        todayTrips.filter { $0.currentStatus == .delayed }.count
    }

    private var tripsSummary: [(String, Int, Color)] {
        let onTime = todayTrips.filter { $0.currentStatus == .onTime }.count
        let delayed = todayTrips.filter { $0.currentStatus == .delayed }.count
        let cancelled = todayTrips.filter { $0.currentStatus == .cancelled }
            .count
        let scheduled = todayTrips.filter { $0.currentStatus == .scheduled }
            .count
        let completed = todayTrips.filter { $0.currentStatus == .completed }
            .count
        return [
            (
                category: "On-Time", count: onTime,
                color: Color.tripStatusColor(for: .onTime)
            ),
            (
                category: "Delayed", count: delayed,
                color: Color.tripStatusColor(for: .delayed)
            ),
            (
                category: "Cancelled", count: cancelled,
                color: Color.tripStatusColor(for: .cancelled)
            ),
            (
                category: "Scheduled", count: scheduled,
                color: Color.tripStatusColor(for: .scheduled)
            ),
            (
                category: "Completed", count: completed,
                color: Color.tripStatusColor(for: .completed)
            ),
        ]
    }
}

#Preview {
    TripManagerDashboardView()
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
}
