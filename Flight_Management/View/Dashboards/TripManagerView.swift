import SwiftData
import SwiftUI

struct TripManagerView: View {
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager

    @Query(sort: \Trip.scheduledDepartureTime, order: .forward) var trips:
        [Trip]
    @Query(sort: \Staff.name, order: .forward) var staffs: [Staff]
    @Query(sort: \Aircraft.registrationNumber, order: .forward) var aircrafts:
        [Aircraft]
    @Query var routes: [Route]

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    homeView
                        .navigationTitle("Manager")
                        .toolbar {
                            profileHandlerToolbarItem(session: session)
                        }
                }
            }

            Tab("Add Aircraft", systemImage: "airplane") {
                AircraftRegistrationForm()
            }

            Tab("Routes", systemImage: "map") {
                NavigationStack {
                    RouteListView()
                }
            }

            Tab("Schedule", systemImage: "calendar.badge.plus") {
                TripRegistrationForm()
            }

            Tab("All Trips", systemImage: "pin") {
                NavigationStack {
                    TripListView()
                }
            }
        }
    }

    var homeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
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

                    TripsDonutChartView(data: tripsSummary)
                        .frame(height: 220)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(
                                Color(.systemBackground)
                            )
                        )
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading) {
                    Text("Active Crew")
                        .font(.headline)
                    Text("Currently on duty")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
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
                .frame(height: 120)

                VStack(alignment: .leading) {
                    Text("Active Aircraft")
                        .font(.headline)
                    Text("Currently assigned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeAircraft, id: \.id) { ac in
                            NavigationLink(
                                destination: AircraftDetailView(
                                    aircraft: ac
                                )
                            ) {
                                ListRow(aircraft: ac)
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
                .frame(height: 120)

                VStack(alignment: .leading) {
                    Text("All Routes")
                        .font(.headline)
                    Text("View upcoming flights per route")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
    }

    // MARK: Helpers
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
            ("On-Time", onTime, Color.tripStatusColor(for: .onTime)),
            ("Delayed", delayed, Color.tripStatusColor(for: .delayed)),
            ("Cancelled", cancelled, Color.tripStatusColor(for: .cancelled)),
            ("Scheduled", scheduled, Color.tripStatusColor(for: .scheduled)),
        ]
    }

    private var activeCrew: [Staff] {
        return staffs.filter { $0.currentStatus == .onDuty }
    }

    private var activeAircraft: [Aircraft] {
        return aircrafts.filter { $0.currentTrip != nil }
    }
}

#Preview {
    TripManagerView()
}
