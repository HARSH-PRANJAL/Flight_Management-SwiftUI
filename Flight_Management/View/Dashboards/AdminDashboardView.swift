import Charts
import SwiftData
import SwiftUI

struct AdminDashboardView: View {
    @Query(sort: \Trip.scheduledDepartureTime, order: .forward) var trips:
        [Trip]
    @Query(sort: \Staff.name, order: .forward) var staffs: [Staff]
    @State private var showingTripList: Bool = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        CardView(
                            title: "On-Time Performance",
                            value: "\(onTimePercentage)%",
                            subtitle: "Flights today",
                            icon: "clock.fill",
                            iconColor: Color(.systemGreen).opacity(0.75),
                            background: Color(.systemBackground)
                        )

                        CardView(
                            title: "Delayed Flights",
                            value: "\(delayedCount)",
                            subtitle: "Today",
                            icon: "airplane.departure",
                            iconColor: Color(.systemRed).opacity(0.75),
                            background: Color(.systemBackground)
                        )
                    }
                    .padding(.horizontal, 16)

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
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            cardTheme()
                        )
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Crew Status Overview")
                                .font(.headline)
                            Text("Today's Availability")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        DonutChartView(
                            data: crewStatusCounts,
                            defaultTitle: "Total staff"
                        )
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            cardTheme()
                        )
                    }
                    .padding(.horizontal, 16)

                    if upcomingTrips.count != 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upcoming Flights")
                                .font(.headline)
                            Text("Next 6 hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            UpcomingTripsScrollView(trips: upcomingTrips)
                                .frame(height: 140)
                            HStack {
                                Spacer()
                                Button("View more") {
                                    showingTripList = true
                                }
                                .font(.subheadline)
                                .tint(Color(.systemBlue))
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Admin")
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showingTripList) {
            TripListView(externalTrips: upcomingTrips)
        }
    }
}

// MARK: Data for display
extension AdminDashboardView {
    private var todayTrips: [Trip] {
        let calendar = Calendar.current
        return trips.filter {
            calendar.isDateInToday($0.scheduledDepartureTime)
        }
    }

    private var onTimePercentage: Int {
        let total = todayTrips.filter { !$0.isCancelled }.count
        guard total > 0 else { return 100 }
        let onTime = todayTrips.filter { $0.currentStatus == .onTime }.count
        return Int((Double(onTime) / Double(total)) * 100)
    }

    private var delayedCount: Int {
        todayTrips.filter { $0.currentStatus == .delayed }.count
    }

    private var tripsSummary: [(String, Int)] {
        let onTime = todayTrips.filter { $0.currentStatus == .onTime }.count
        let delayed = todayTrips.filter { $0.currentStatus == .delayed }.count
        let cancelled = todayTrips.filter { $0.currentStatus == .cancelled }
            .count
        let scheduled = todayTrips.filter { $0.currentStatus == .scheduled }
            .count
        return [
            (category: "On-Time", count: onTime),
            (category: "Delayed", count: delayed),
            (category: "Cancelled", count: cancelled),
            (category: "Scheduled", count: scheduled),
        ]
    }

    private var crewStatusCounts: [(String, Int)] {
        let available = staffs.filter { $0.currentStatus == .available }.count
        let onDuty = staffs.filter { $0.currentStatus == .onDuty }.count
        let unavailable = staffs.filter { $0.currentStatus == .unavailable }
            .count
        return [
            (category: "Available", count: available),
            (category: "On Duty", count: onDuty),
            (category: "Unavailable", count: unavailable),
        ]
    }

    private var upcomingTrips: [Trip] {
        let now = Date()
        let until =
            Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
        return trips.filter {
            $0.currentStatus == .scheduled && !$0.isCancelled && !$0.isCompleted
                && $0.scheduledDepartureTime >= now
                && $0.scheduledDepartureTime <= until
        }
        .sorted { $0.scheduledDepartureTime < $1.scheduledDepartureTime }
    }

}

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
