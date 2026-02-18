import SwiftUI

struct RouteDetailView: View {
    let route: Route
    
    @Environment(SessionManager.self) var session
    @Environment(NotificationManager.self) var notificationManager
    
    @State private var isEditPageShowing: Bool = false

    var isAdmin: Bool {
        session.user?.role == UserRole.admin.rawValue
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack {
                    primaryCard
                    tripDetails

                    if currentTrip.count != 0 {
                        tripCards(
                            title: "Current Trip",
                            count: currentTrip.count,
                            trips: currentTrip,
                            imageName: "clock.badge.airplane",
                            imageColor: Color(.systemCyan)
                        )
                    } else {
                        Text("No active trips yet…")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .foregroundStyle(Color(.systemGray3))
                            .padding(.vertical, 20)
                    }

                    if tripHistory.count != 0 {
                        tripCards(
                            title: "Trip history",
                            count: tripHistory.count,
                            trips: tripHistory,
                            imageName: "checkmark.circle",
                            imageColor: Color(.systemGreen)
                        )
                    } else {
                        Text("No trip history yet…")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .foregroundStyle(Color(.systemGray3))
                            .padding(.vertical, 20)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)

        }
        .toolbar {
            if isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isEditPageShowing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditPageShowing) {
            NavigationStack {
                RouteRegistrationForm(route: route, isPresented: $isEditPageShowing)
            }
        }
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Text("\(route.name)")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            Text("Total Airports : \(route.nodes.count)")
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .padding(.bottom, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }

    var tripDetails: some View {
        VStack(spacing: 0) {
            Text("Trip Details :")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            HStack {
                Text("Total Trips : \(route.trips.count)")
                Text("Scheduled Trips : \(countScheduleTrips)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }

    var countScheduleTrips: Int {
        return route.trips.filter { $0.currentStatus == .scheduled }.count
    }

    var currentTrip: [Trip] {
        return route.trips.filter {
            $0.currentStatus == .onTime || $0.currentStatus == .delayed
        }.sorted(by: { $0.scheduledDepartureTime < $1.scheduledDepartureTime })
    }

    var tripHistory: [Trip] {
        return route.trips.filter {
            $0.isCompleted == true || $0.isCancelled == true
        }.sorted(by: { $0.estimatedArrivalTime > $1.estimatedArrivalTime })
    }

}

#Preview {
    NavigationStack {
        RouteDetailView(
            route: Route(
                name: "London to New York"
            )
        )
    }
}
