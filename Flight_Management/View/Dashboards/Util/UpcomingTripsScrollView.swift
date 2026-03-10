import SwiftUI

struct UpcomingTripsScrollView: View {
    let trips: [Trip]
    var noDataMessage: String = "No upcoming trips in next 6 hours"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(trips, id: \.id) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        CardView(
                            title: trip.tripNumber,
                            value: formatDate(
                                trip.scheduledDepartureTime,
                                format: "dd MMM, HH:mm"
                            ),
                            subtitle:
                                "Planned arrival: \(formatDate(trip.estimatedArrivalTime, format: "dd MMM, HH:mm"))",
                            icon: "airplane",
                            iconColor: Color(.systemBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 16)
                    .padding(.bottom, 8)
                }
                if trips.isEmpty {
                    Text(noDataMessage)
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
