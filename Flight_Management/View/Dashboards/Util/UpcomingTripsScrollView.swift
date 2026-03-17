import SwiftUI

struct UpcomingTripsScrollView<T>: View {
    let trips: [Trip]
    var noDataMessage: String = "No upcoming trips in next 6 hours"

    @Binding var selectedTrip: Trip?
    @Binding var presentedSheet: T?
    var onSelect: (Trip) -> T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(trips, id: \.id) { trip in
                    CardView(
                        title: trip.tripNumber,
                        value: formatDate(
                            trip.scheduledDepartureTime,
                            format: "dd MMM, HH:mm"
                        ),
                        subtitle:
                            "Planned arrival: \(formatDate(trip.estimatedArrivalTime, format: "dd MMM, HH:mm"))",
                        icon: "airplane",
                        iconColor: Color(.systemBlue),
                        clickable: false
                    )
                    .padding(.leading, 16)
                    .padding(.bottom, 8)
                    .onTapGesture {
                        selectedTrip = trip
                        presentedSheet = onSelect(trip)
                    }
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

