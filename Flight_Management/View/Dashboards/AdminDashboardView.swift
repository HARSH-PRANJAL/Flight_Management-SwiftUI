import Charts
import SwiftData
import SwiftUI

struct AdminDashboardView: View {
    @Query private var todayTrips: [Trip]
    @Query private var upcomingTrips: [Trip]
    @Query private var availableStaff: [Staff]
    @Query private var onDutyStaff: [Staff]
    @Query private var unavailableStaff: [Staff]

    @State private var showingTripList: Bool = false

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

            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
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

                    VStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Daily Trip Status")
                                .font(.headline)
                            Text("Overview of all trips today")
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
                            Text("Overall availability today")
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
                                    showingTripList = true
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
            .navigationTitle("Admin")
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showingTripList) {
            NavigationStack {
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

// MARK: - Data for display
extension AdminDashboardView {

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
        let cancelled = completedTrips.filter { $0.isCancelled }.count

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
