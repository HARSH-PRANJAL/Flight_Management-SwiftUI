import SwiftUI
import Charts
import SwiftData

struct AdminDashboardView: View {
    @Query(sort: \Trip.scheduledDepartureTime, order: .forward) var trips: [Trip]
    @Query(sort: \Staff.name, order: .forward) var staffs: [Staff]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        DashboardCardView(
                            title: "On-Time Performance",
                            value: "\(onTimePercentage)%",
                            subtitle: "Flights today",
                            icon: "clock.fill",
                            iconColor: Color(.systemGreen).opacity(0.75),
                            background: Color(.systemBackground)
                        )
                        
                        DashboardCardView(
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
                            Text("Daily Flight Status")
                                .font(.headline)
                            Text("Overview of all flights today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TripsDonutChartView(data: tripsSummary)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                            .shadow(color: Color.black.opacity(0.05),
                                radius: 5, x:0, y:2)
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
                        
                        CrewStatusChartView(data: crewStatusCounts)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                            .shadow(color: Color.black.opacity(0.05),
                                radius: 5, x:0, y:2)
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
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: Data for display
extension AdminDashboardView {
    private var todayTrips: [Trip] {
        let calendar = Calendar.current
        return trips.filter { calendar.isDateInToday($0.scheduledDepartureTime) }
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

    private var tripsSummary: [(String, Int, Color)] {
        let onTime = todayTrips.filter { $0.currentStatus == .onTime }.count
        let delayed = todayTrips.filter { $0.currentStatus == .delayed }.count
        let cancelled = todayTrips.filter { $0.currentStatus == .cancelled }.count
        let scheduled = todayTrips.filter { $0.currentStatus == .scheduled }.count
        return [
            ("On-Time", onTime, Color(red: 0.91, green: 0.47, blue: 0.38)),
            ("Delayed", delayed, Color.green),
            ("Cancelled", cancelled, Color.gray),
            ("Scheduled", scheduled, Color.yellow)
        ]
    }

    private var crewStatusCounts: [(String, Int, Color)] {
        let active = staffs.filter { $0.currentStatus == .available }.count
        let onDuty = staffs.filter { $0.currentStatus == .onDuty }.count
        let inactive = staffs.filter { $0.currentStatus == .unavailable }.count
        return [
            ("Active", active, Color(red: 0.91, green: 0.47, blue: 0.38)),
            ("On Duty", onDuty, Color.teal),
            ("Inactive", inactive, Color.blue)
        ]
    }

    private var upcomingTrips: [Trip] {
        let now = Date()
        let until = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
        return trips.filter {
            !$0.isCancelled && !$0.isCompleted && $0.scheduledDepartureTime >= now && $0.scheduledDepartureTime <= until
        }
        .sorted { $0.scheduledDepartureTime < $1.scheduledDepartureTime }
    }

}

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
