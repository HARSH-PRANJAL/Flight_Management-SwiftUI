import SwiftUI

struct ListRow: View, Identifiable {
    let id: UUID = UUID()
    let profileImage: Image?
    let title: String
    let subtitle: String
    let statusBadge: StatusBadge?
    let associatedTrip: Trip?
    let showFallbackImage: Bool

    init(
        profileImage: Image?,
        title: String,
        subtitle: String,
        status: StatusBadge? = nil,
        associatedTrip: Trip? = nil,
        showFallbackImage: Bool = false
    ) {
        self.profileImage = profileImage
        self.title = title
        self.subtitle = subtitle
        self.statusBadge = status
        self.associatedTrip = associatedTrip
        self.showFallbackImage = showFallbackImage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                profileImageView

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.label))
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    statusBadgeView
                }
            }
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        Group {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
            } else {
                if showFallbackImage {
                    fallbackStaffImage()
                } else {
                    EmptyView()
                }
            }
        }
        .clipShape(Circle())
        .frame(width: 48, height: 48)
        .overlay {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var statusBadgeView: some View {
        if let statusBadge = self.statusBadge {
            StatusCapsuleView(statusBadge: statusBadge, onlyIndicator: true)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Initialisers
extension ListRow {
    init(staff: Staff) {
        self.init(
            profileImage: staff.avatarImage,
            title: staff.name,
            subtitle: staff.designation.rawValue,
            status: .from(staffStatus: staff.currentStatus),
            showFallbackImage: true
        )
    }

    init(aircraft: Aircraft) {
        self.init(
            profileImage: nil,
            title: aircraft.registrationNumber,
            subtitle: aircraft.type,
            status: .from(aircraftStatus: aircraft.currentStatus),
            associatedTrip: nil
        )
    }

    init(trip: Trip) {
        self.init(
            profileImage: nil,
            title: trip.flightNumber,
            subtitle: formatDate(
                trip.scheduledDepartureTime,
                format: "dd-MM-yyyy HH:mm"
            ),
            status: .from(tripStatus: trip.currentStatus),
            associatedTrip: trip
        )
    }

    init(route: Route) {
        self.init(
            profileImage: nil,
            title: route.name,
            subtitle:
                "Airports: \(route.nodes.count)   Total trips: \(route.trips.count)",
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
