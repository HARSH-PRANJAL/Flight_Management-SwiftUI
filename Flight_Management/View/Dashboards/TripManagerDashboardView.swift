import SwiftData
import SwiftUI

struct TripManagerDashboardView: View {
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager

    @Query(sort: \Trip.scheduledDepartureTime, order: .forward) var trips:
        [Trip]
    @Query(sort: \Staff.name, order: .forward) var staffs: [Staff]
    @Query(sort: \Aircraft.registrationNumber, order: .forward) var aircrafts:
        [Aircraft]
    @Query var routes: [Route]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    tripDetailCards

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
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: UI
extension TripManagerDashboardView {

    var tripDetailCards: some View {
        HStack(spacing: 12) {
            CardView(
                title: "On-Time Performance",
                value: "\(onTimePercentage)%",
                subtitle: "Flights today",
                icon: "clock.fill",
                iconColor: Color(.systemGreen).opacity(0.75)
            )

            CardView(
                title: "Delayed Flights",
                value: "\(delayedCount)",
                subtitle: "Today",
                icon: "airplane.departure",
                iconColor: Color(.systemRed).opacity(0.75)
            )
        }
    }

    @ViewBuilder
    var activeStaffCards: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("Active Crew")
                    .font(.headline)
                Text("Currently on duty")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack {
                    HStack(spacing: 12) {
                        ForEach(activeCrew, id: \.id) { staff in
                            NavigationLink(
                                destination: StaffDetailView(staff: staff)
                            ) {
                                ListRow(staff: staff)
                                    .frame(width: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .background(cardTheme())
            }
            .frame(height: 220)
        }
    }

    @ViewBuilder
    var ongoingTrips: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("Trips for today")
                    .font(.headline)
                Text("Ongoing or scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack {
                    HStack(spacing: 12) {
                        ForEach(todayTrips, id: \.id) { trip in
                            NavigationLink(
                                destination: TripDetailView(
                                    trip: trip
                                )
                            ) {
                                ListRow(trip: trip)
                                    .frame(width: 200)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .background(cardTheme())
            }
            .frame(height: 220)
        }
    }
}

// MARK: Util
extension TripManagerDashboardView {
    private var todayTrips: [Trip] {
        let calendar = Calendar.current
        return trips.filter {
            calendar.isDateInToday($0.scheduledDepartureTime)
        }
    }

    private var onTimePercentage: Int {
        let total = todayTrips.filter { !$0.isCancelled }.count

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
        ]
    }

    private var activeCrew: [Staff] {
        return staffs.filter { $0.currentStatus == .onDuty }
    }
}

#Preview {
    TripManagerDashboardView()
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
}
