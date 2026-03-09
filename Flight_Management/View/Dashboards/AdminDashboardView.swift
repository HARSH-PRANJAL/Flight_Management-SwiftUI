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
                            title: "On-Time Performance",
                            value: "\(onTimePercentage)%",
                            subtitle: "Today",
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
                            data: tripsSummary,
                            defaultTitle: "Total trips"
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

    private var onTimePercentage: Int {
        let total = todayTrips.filter {
            $0.currentStatus == .onTime || $0.currentStatus == .delayed
        }.count
        guard total > 0 else { return 0 }
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
        let completed = todayTrips.filter { $0.isCompleted }.count
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
