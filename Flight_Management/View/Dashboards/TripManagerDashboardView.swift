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
                                    showingTripList = true
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
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CardView(
                    title: "Scheduled Trips",
                    value: "\(scheduledTripsCount)",
                    subtitle: "Today",
                    icon: "clock.fill",
                    iconColor: Color.tripStatusColor(for: .scheduled)
                )

                CardView(
                    title: "Completed Trips",
                    value: "\(completedTripsCount)",
                    subtitle: "Today",
                    icon: "airplane.arrival",
                    iconColor: Color.tripStatusColor(for: .completed)
                )
            }
            HStack(spacing: 16) {
                CardView(
                    title: "On time Trips",
                    value: "\(liveOntimeTripsCount)",
                    subtitle: "Operating now",
                    icon: "clock.badge.airplane",
                    iconColor: Color.tripStatusColor(for: .onTime)
                )

                CardView(
                    title: "Delayed Trips",
                    value: "\(liveDelayedTripsCount)",
                    subtitle: "Operating now",
                    icon: "clock.badge.airplane",
                    iconColor: Color.tripStatusColor(for: .delayed)
                )
            }
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

    var scheduledTripsCount: Int {
        return todayTrips.filter { $0.currentStatus == .scheduled }.count
    }

    var completedTripsCount: Int {
        return todayTrips.filter { $0.isCompleted }.count
    }

    var liveOntimeTripsCount: Int {
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
