import SwiftUI

struct UpcomingTripsScrollView: View {
    let trips: [Trip]
    var noDataMessage: String = "No upcoming trips in next 6 hours"
    
    @State private var selectedTrip: Trip? = nil
    @State private var isTripDetailPresented: Bool = false

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
                        iconColor: Color(.systemBlue)
                    )
                    .padding(.leading, 16)
                    .padding(.bottom, 8)
                    .onTapGesture {
                        selectedTrip = trip
                        isTripDetailPresented = true
                    }
                }
                if trips.isEmpty {
                    Text(noDataMessage)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $isTripDetailPresented) {
            NavigationStack {
                if let trip = selectedTrip {
                    TripDetailView(trip: trip)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    isTripDetailPresented = false
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    UpcomingTripsScrollView(trips: [])
}
