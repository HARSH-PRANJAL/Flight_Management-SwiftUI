import SwiftUI

struct DetailView: View {
    var profileImage: Image?
    var titleText: String
    var subTitleText: String
    var detailText: String?
    var statusBadge: StatusBadge
    var primaryRow: ListRow?
    var listData: [ListRow]

    var onActionButtonTapped: (() -> Void)? = {
        print("test")
    }
    var actionButtonTitle: String = "Change Status"
    var currentTaskTitle: String = "Current Task"
    var listDataTitle: String = "Completed Tasks"

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    primaryCard
                        .padding(.bottom, 10)

                    if onActionButtonTapped != nil {
                        actionButton
                            .shadow(
                                color: Color.black.opacity(0.07),
                                radius: 2,
                                x: 0,
                                y: 2
                            )
                    }

                    if primaryRow != nil {
                        primaryRowCard
                    }

                    if !listData.isEmpty {
                        listRowsCard
                    }
                }
                .padding(.horizontal, 15)
            }
            .scrollIndicators(.hidden)
        }
    }

    var listRowsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label {
                Text(listDataTitle)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(Color(.systemGreen))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            LazyVStack(spacing: 0) {
                ForEach(listData, id: \.title) { row in
                    row
                        .padding(.horizontal, 16)
                        .background(
                            cardTheme
                        )
                        .padding(.bottom, 10)
                }
            }
        }
    }

    var primaryRowCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label {
                Text(currentTaskTitle)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: "clock.badge.airplane")
                    .foregroundStyle(Color(.systemCyan))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            primaryRow!
                .padding(.leading, 16)
                .background(
                    cardTheme
                )
        }
        .padding(.bottom, 25)
    }

    var actionButton: some View {
        Text(actionButtonTitle)
            .font(.title3)
            .foregroundColor(Color(.systemBlue).opacity(0.5))
            .contrast(1.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                cardTheme
            )
            .onTapGesture {
                onActionButtonTapped!()
            }
            .padding(.bottom, 30)
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            displayImage
                .padding(.bottom, 20)
            Text(titleText)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            Text(subTitleText)
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .padding(.bottom, 10)
            if let detailText = self.detailText {
                TextWithCopyView(text: detailText)
            }
            statusCapsule
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme
        )
    }

    var statusCapsule: some View {
        StatusCapsuleView(statusBadge: statusBadge)
    }

    var displayImage: some View {
        Group {
            if profileImage != nil {
                profileImage!
                    .resizable()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            Color(.secondarySystemBackground),
                            lineWidth: 3
                        )
                    )
                    .foregroundStyle(.gray)
            } else {
                EmptyView()
            }
        }
    }
    
    var cardTheme: some View {
        Color(.tertiarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: Color.black.opacity(0.07),
                radius: 2,
                x: 0,
                y: 2
            )
    }
}


// MARK: Init
extension DetailView {
    init(aircraft: Aircraft) {
        self.init(
            profileImage: nil,
            titleText: aircraft.type,
            subTitleText: "Total trips - \(aircraft.totalTripsOperated)",
            detailText: aircraft.registrationNumber,
            statusBadge: .from(aircraftStatus: aircraft.currentStatus),
            primaryRow: aircraft.currentTrip != nil ? ListRow(trip: aircraft.currentTrip!) : nil,
            listData: aircraft.completedTrips.map { data in
                ListRow(trip: data)
            }
        )
    }

    init(trip: Trip) {
        self.init(
            profileImage: nil,
            titleText: trip.flightNumber,
            subTitleText: trip.route.name,
            detailText: "Aircraft: \(trip.aircraft.type)",
            statusBadge: .from(tripStatus: trip.currentStatus),
            primaryRow: nil,
            listData: trip.staffs.map { staff in
                ListRow(
                    profileImage: staff.avatarImage,
                    title: staff.name,
                    subtitle: staff.designation.rawValue,
                    status: StatusBadge.from(staffStatus: staff.currentStatus)
                )
            },
            actionButtonTitle: "Update Status",
            currentTaskTitle: "Flight Crew",
            listDataTitle: "Assigned Staff"
        )
    }

    init(staff: Staff) {
        self.init(
            profileImage: staff.avatarImage,
            titleText: staff.name,
            subTitleText: staff.designation.rawValue,
            detailText: staff.email,
            statusBadge: .from(staffStatus: staff.currentStatus),
            primaryRow: staff.currentTrip != nil ? ListRow(trip: staff.currentTrip!) : nil,
            listData: staff.completedTrips.map { trip in
                ListRow(trip: trip)
            },
            actionButtonTitle: "Change Availability",
            currentTaskTitle: "Current Assignment",
            listDataTitle: "Completed Flights"
        )
    }
}


#Preview("Staff") {
        DetailView(
            profileImage: Image(systemName: "person.crop.circle.fill"),
            titleText: "Sarah Johnson",
            subTitleText: "Senior Software Engineer",
            detailText: "hp@gmail.com",
            statusBadge: StatusBadge(label: "Active", backgroundColor: Color.onTime),
            primaryRow: ListRow(
                profileImage: nil,
                title: "Implement User Authentication",
                subtitle: "Create login and signup functionality with JWT tokens",
                status: StatusBadge(label: "Cancelled", backgroundColor: Color.tripStatusColor(for: .cancelled))
            ),
            listData: [
                ListRow(profileImage: nil, title: "Design Database Schema", subtitle: "Complete"),
                ListRow(profileImage: nil, title: "Design Database Schem", subtitle: "Complete"),
                ListRow(profileImage: nil, title: "Design Database Sche", subtitle: "Complete"),
                ListRow(profileImage: nil, title: "Design Database Sch", subtitle: "Complete"),
                ListRow(profileImage: nil, title: "Design Database ", subtitle: "Complete"),
                ListRow(profileImage: nil, title: "Design Databas", subtitle: "Complete")
            ]
        )
}

#Preview("Aircraft") {
    let mockRoute = Route(name: "New York to London")
    mockRoute.nodes = [
        RouteNode(plannedArrivalOffsetMinutes: 120, airport: Airport(code: "JFK", name: "John F. Kennedy", city: "New York", country: "USA")),
        RouteNode(plannedArrivalOffsetMinutes: 480, airport: Airport(code: "LHR", name: "London Heathrow", city: "London", country: "UK"))
    ]
    
    let mockTrip1 = Trip(
        staff: [],
        aircraft: Aircraft(
            registrationNumber: "N12345",
            type: "Boeing 737",
            seatingCapacity: 180,
            minimumStaffRequired: [:]
        ),
        nodeStatuses: [],
        route: mockRoute,
        scheduledDepartureTime: Date(),
        flightNumber: "AA-100",
        isCancelled: false
    )
    mockTrip1.isCompleted = true
    
    let mockTrip2 = Trip(
        staff: [],
        aircraft: Aircraft(
            registrationNumber: "N12345",
            type: "Boeing 737",
            seatingCapacity: 180,
            minimumStaffRequired: [:]
        ),
        nodeStatuses: [],
        route: mockRoute,
        scheduledDepartureTime: Date().addingTimeInterval(-86400),
        flightNumber: "AA-101",
        isCancelled: false
    )
    mockTrip2.isCompleted = true
    
    let mockCurrent = Trip(
        staff: [],
        aircraft: Aircraft(
            registrationNumber: "N12345",
            type: "Boeing 737",
            seatingCapacity: 180,
            minimumStaffRequired: [:]
        ),
        nodeStatuses: [],
        route: mockRoute,
        scheduledDepartureTime: Date().addingTimeInterval(3600),
        flightNumber: "AA-102",
        isCancelled: false
    )
    
    let mockAircraft = Aircraft(
        registrationNumber: "N12345",
        type: "Boeing 737",
        seatingCapacity: 180,
        minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 5]
    )
    mockAircraft.trips = [mockTrip1, mockTrip2, mockCurrent]
    mockAircraft.currentTrip = mockCurrent
    
    return DetailView(aircraft: mockAircraft)
}
