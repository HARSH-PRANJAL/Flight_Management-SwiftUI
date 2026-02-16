import SwiftUI

struct RouteDetailView: View {
    let route: Route

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack {
                primaryCard
                tripDetails
                
                if currentTrip.count != 0 {
                    currentTripCards
                } else {
                    Text("No trips started yet.")
                        .font(.largeTitle)
                        .fontWeight(.ultraLight)
                        .foregroundStyle(Color(.systemGray5))
                }
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
                Text("Completed Trips : \(countCompletedTrips)")
                Text("Scheduled Trips : \(countScheduleTrips)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }
    
    var currentTripCards: some View {
        VStack(alignment: .leading, spacing: 0) {
                Label {
                    Text("Current Trips")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                } icon: {
                    Image(systemName: "clock.badge.airplane")
                        .foregroundStyle(Color(.systemCyan))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Group {
                ForEach(currentTrip, id: \.id) { trip in
                    NavigationLink(destination: {
                        DetailView(trip: trip)
                    }, label: {
                        ListRow(trip: trip)
                    })
                }
            }
            .padding(.leading, 16)
            .background(
                cardTheme()
            )
        }
        .padding(.bottom, 25)
    }

    var countCompletedTrips: Int {
        return route.trips.filter(\.isCompleted).count
    }

    var countScheduleTrips: Int {
        return route.trips.filter { $0.currentStatus == .scheduled }.count
    }
    
    var currentTrip: [Trip] {
        return route.trips.filter {
            $0.currentStatus == .onTime || $0.currentStatus == .delayed
        }.sorted(by: { $0.scheduledDepartureTime < $1.scheduledDepartureTime })
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
