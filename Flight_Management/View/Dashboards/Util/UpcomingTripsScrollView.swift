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
            Image(systemName: "airplane")
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(trip.flightNumber)
                    .font(.headline)
                HStack {
                    Text(departure)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(arrival)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .frame(width: 300, height: 100)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
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
