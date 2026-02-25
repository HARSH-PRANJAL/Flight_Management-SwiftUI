import SwiftData
import SwiftUI

struct UpcomingTripCard: View {
    let trip: Trip

    private var departure: String {
        formatDate(trip.scheduledDepartureTime, format: "h:mm a")
    }

    private var arrival: String {
        formatDate(trip.estimatedArrivalTime, format: "h:mm a")
    }

    var body: some View {
        HStack {
            CardView(
                title: trip.flightNumber,
                value: departure,
                subtitle: "Planned arrival: \(arrival)",
                icon: "airplane",
                iconColor: Color(.systemBlue)
            )
            .padding(.horizontal, 8)

            Spacer()
        }
        .frame(width: 220, height: 100)
    }
}

struct UpcomingTripsScrollView: View {
    let trips: [Trip]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(trips, id: \.id) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        UpcomingTripCard(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
                if trips.isEmpty {
                    Text("No upcoming flights in next 6 hours")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

#Preview {
    UpcomingTripsScrollView(trips: [])
}
