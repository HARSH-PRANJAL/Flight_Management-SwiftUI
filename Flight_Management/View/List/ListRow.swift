import SwiftUI

struct ListRow: View, Identifiable {
    let id: UUID = UUID()
    let profileImage: Image?
    let title: String
    let subtitle: String
    let metadata: String?
    let statusBadge: StatusBadge?
    let associatedTrip: Trip?
    let showFallbackImage: Bool

    init(
        profileImage: Image?,
        title: String,
        subtitle: String,
        metadata: String? = nil,
        status: StatusBadge? = nil,
        associatedTrip: Trip? = nil,
        showFallbackImage: Bool = false
    ) {
        self.profileImage = profileImage
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata
        self.statusBadge = status
        self.associatedTrip = associatedTrip
        self.showFallbackImage = showFallbackImage
    }

    var body: some View {
        HStack(spacing: 12) {
            profileImageView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)

                if let metadata, !metadata.isEmpty {
                    Text(metadata)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let statusBadge {
                StatusCapsuleView(statusBadge: statusBadge, onlyIndicator: true)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var profileImageView: some View {
        Group {
            if let profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
            } else if showFallbackImage {
                fallbackStaffImage()
            } else {
                EmptyView()
            }
        }
        .clipShape(Circle())
        .frame(width: 44, height: 44)
        .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
    }

}

// MARK: - Initialisers
extension ListRow {
    init(staff: Staff) {
        let meta: String?
        if let trip = staff.currentTrip {
            meta = "Current: \(trip.flightNumber)"
        } else if let next = staff.nextScheduledTrip {
            meta = "Next: \(next.flightNumber) • \(formatDate(next.scheduledDepartureTime, format: "dd MMM"))"
        } else {
            meta = String(format: "%.0fh total • \(staff.completedTrips.count) trips", staff.totalTripHours)
        }
        self.init(
            profileImage: staff.avatarImage,
            title: staff.name,
            subtitle: staff.designation.rawValue,
            metadata: meta,
            status: .from(staffStatus: staff.currentStatus),
            showFallbackImage: true
        )
    }

    init(aircraft: Aircraft) {
        let meta = "\(aircraft.seatingCapacity) seats • \(aircraft.totalTripsOperated) trips"
        self.init(
            profileImage: nil,
            title: aircraft.registrationNumber,
            subtitle: aircraft.type,
            metadata: meta,
            status: .from(aircraftStatus: aircraft.currentStatus)
        )
    }

    init(trip: Trip) {
        let origin = trip.route.nodes.first?.airport.code ?? "_"
        let dest = trip.route.nodes.last?.airport.code ?? "_"
        let meta = "\(origin) → \(dest) • \(formatDate(trip.estimatedArrivalTime, format: "HH:mm"))"
        self.init(
            profileImage: nil,
            title: trip.flightNumber,
            subtitle: formatDate(trip.scheduledDepartureTime, format: "dd MMM, HH:mm"),
            metadata: meta,
            status: .from(tripStatus: trip.currentStatus),
            associatedTrip: trip
        )
    }

    init(route: Route) {
        let origin = route.nodes.first?.airport.code ?? "_"
        let dest = route.nodes.last?.airport.code ?? "_"
        let meta = route.nodes.isEmpty ? "\(route.trips.count) trips" : "\(origin) → \(dest) • \(route.totalPlannedDurationMinutes)min • \(route.trips.count) trips"
        self.init(
            profileImage: nil,
            title: route.name,
            subtitle: "\(route.nodes.count) airports",
            metadata: meta,
            status: nil
        )
    }
}

#Preview("Staff List Row") {
    let staff = Staff(
        name: "John Doe",
        designation: .pilot,
        gender: .male,
        email: "john@example.com",
        dob: Date()
    )

    ListRow(
        staff: staff
    )
    .padding()
}

#Preview("Aircraft List Row") {
    let aircraft = Aircraft(
        registrationNumber: "N12345",
        type: "Boeing 737",
        seatingCapacity: 180,
        minimumStaffRequired: [.pilot: 2, .cabinCrew: 4]
    )

    ListRow(
        aircraft: aircraft
    )
    .padding()
}

#Preview("Available Staff") {
    let staff = Staff(
        name: "Jane Smith",
        designation: .coPilot,
        gender: .female,
        email: "jane@example.com",
        dob: Date()
    )

    VStack(spacing: 1) {
        ListRow(staff: staff).id(UUID())
        ListRow(staff: staff).id(UUID())
        ListRow(staff: staff).id(UUID())
    }
}
