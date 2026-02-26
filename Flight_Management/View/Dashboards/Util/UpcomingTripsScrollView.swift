import SwiftUI

struct UpcomingTripsScrollView: View {
    let trips: [Trip]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(trips, id: \.id) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        CardView(
                            title: trip.flightNumber,
                            value: formatDate(
                                trip.scheduledDepartureTime,
                                format: "h:mm a"
                            ),
                            subtitle:
                                "Planned arrival: \(formatDate(trip.estimatedArrivalTime, format: "h:mm a"))",
                            icon: "airplane",
                            iconColor: Color(.systemBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 16)
                    .padding(.bottom, 8)
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
