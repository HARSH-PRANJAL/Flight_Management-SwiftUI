import SwiftUI

struct ListRow: View {
    let profileImage: Image?
    let title: String
    let subtitle: String
    let statusBadge: StatusBadge?
    
    init(
        profileImage: Image?,
        title: String,
        subtitle: String,
        status: StatusBadge? = nil
    ) {
        self.profileImage = profileImage
        self.title = title
        self.subtitle = subtitle
        self.statusBadge = status
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        if let profileImage = profileImage {
            profileImage
                .resizable()
                .scaledToFill()
                .foregroundStyle(.gray)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1)
                }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var statusBadgeView: some View {
        if let statusBadge = self.statusBadge {
            StatusCapsuleView(statusBadge: statusBadge)
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
            status: .from(staffStatus: staff.currentStatus)
        )
    }
    
    init(aircraft: Aircraft) {
        self.init(
            profileImage: nil,
            title: aircraft.registrationNumber,
            subtitle: aircraft.type,
            status: nil
        )
    }
    
    init(trip: Trip) {
        self.init(profileImage: nil, title: trip.flightNumber, subtitle:  formatDate(trip.scheduledDepartureTime, format: "dd-MM-yyyy HH:mm"), status: .from(tripStatus: trip.currentStatus))
    }
}

// MARK: - Previews
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

//#Preview("Trip") {
//    let route = Route(name: "New York - London")
//    route.nodes = [
//        RouteNode(plannedArrivalOffsetMinutes: 120, airport: Airport(code: "JFK", name: "John F. Kennedy", city: "New York", country: "USA")),
//        RouteNode(plannedArrivalOffsetMinutes: 480, airport: Airport(code: "LHR", name: "London Heathrow", city: "London", country: "UK"))
//    ] as [RouteNode]
//    
//    let aircraft = Aircraft(
//        registrationNumber: "N12345",
//        type: "Boeing 737",
//        seatingCapacity: 180,
//        minimumStaffRequired: [.pilot: 2, .cabinCrew: 4]
//    )
//    
//    let trip = Trip(
//        staff: [
//            Staff(
//                name: "Jane Smith",
//                designation: .coPilot,
//                gender: .female,
//                email: "jane@example.com",
//                dob: Date()
//            ),
//            Staff(
//                name: "John Doe",
//                designation: .pilot,
//                gender: .male,
//                email: "john@example.com",
//                dob: Date()
//            )
//        ],
//        aircraft: aircraft,
//        nodeStatuses: [],
//        route: route,
//        scheduledDepartureTime: Date().addingTimeInterval(3600),
//        flightNumber: "BA-100",
//        isCancelled: false
//    )
//    
//    VStack(spacing: 1) {
//        ListRow(trip: trip).id(UUID())
//        ListRow(trip: trip).id(UUID())
//        ListRow(trip: trip).id(UUID())
//    }
//}
//
