import SwiftUI

struct DetailView: View {
    var profileImage: Image?
    var titleText: String
    var subTitleText: String
    var detailText: String?
    var statusBadge: StatusBadge?
    var primaryRow: ListRow?
    var listData: [ListRow]
    var showProfileImage: Bool = false

    var onActionButtonTapped: (() -> Void)? = nil
    var actionButtonTitle: String = "Change Status"
    var currentTaskTitle: String = "Current Task"
    var listDataTitle: String = "Completed Tasks"
    var detail1Title: String = "Email"
    var detail1Value: String = "user@example.com"

    @State private var showImagePreview = false
    @State private var selectedTab: Tab = .detail

    enum Tab: String, CaseIterable {
        case detail = "Detail"
        case tripHistory = "Trip History"
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if listData.isEmpty {
                    detailView
                } else {
                    switch selectedTab {
                    case .detail:
                        detailView
                    case .tripHistory:
                        listRowsCard
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !listData.isEmpty {
                        Picker("View Mode", selection: $selectedTab) {
                            ForEach(Tab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal > 100 {
                            selectedTab = .detail
                        }

                        if horizontal < -100 {
                            selectedTab = .tripHistory
                        }
                    }
            )
        }
        .animation(.linear(duration: 0.5), value: selectedTab)
        .fullScreenCover(isPresented: $showImagePreview) {
            ImagePreviewModal(image: profileImage, title: titleText)
        }
    }

    var detailView: some View {
        ScrollView {
            VStack(spacing: 16) {
                primaryCard
                if onActionButtonTapped != nil {
                    actionButton
                        .padding(.bottom, 16)
                }

                if primaryRow != nil {
                    primaryRowCard
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var listRowsCard: some View {
        List {
            ForEach(listData, id: \.id) { row in
                if let trip = row.associatedTrip {
                    NavigationLink(
                        destination: TripDetailView(trip: trip)
                    ) {
                        row
                    }
                } else {
                    row
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    var primaryRowCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !currentTaskTitle.isEmpty {
                Label {
                    Text(currentTaskTitle)
                        .font(.title3)
                        .foregroundStyle(Color.primary)
                } icon: {
                    Image(systemName: "clock.badge.airplane")
                        .font(.title3)
                        .foregroundStyle(Color(.systemCyan))
                }
            }

            Group {
                if let trip = primaryRow?.associatedTrip {
                    HStack {
                        NavigationLink(destination: TripDetailView(trip: trip))
                        {
                            primaryRow!
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color(.systemGray4))
                            .padding(.trailing, 16)
                    }
                    .buttonStyle(.borderless)
                } else {
                    primaryRow!
                }
            }
            .padding(13)
            .background(
                cardTheme()
            )
        }
        .padding(.bottom, 25)
    }

    var actionButton: some View {
        Button {
            onActionButtonTapped!()
        } label: {
            Text(actionButtonTitle)
                .font(.title3)
                .foregroundColor(Color(.systemBlue).opacity(0.75))
                .contrast(1.5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(cardTheme())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            displayImage
                .padding(.bottom, 20)
            Text(titleText)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            Text(subTitleText)
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .lineLimit(1)
                .padding(.bottom, 10)
            if statusBadge != nil {
                statusCapsule
                    .padding(.bottom, 15)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }

    var statusCapsule: some View {
        StatusCapsuleView(statusBadge: statusBadge!)
    }

    var displayImage: some View {
        Group {
            if profileImage != nil {
                profileImage!
                    .resizable()
                    .onTapGesture {
                        showImagePreview = true
                    }
                    .hoverEffect(.highlight)
            } else {
                if showProfileImage {
                    fallbackStaffImage()
                } else {
                    EmptyView()
                }
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(
                Color(.secondarySystemBackground),
                lineWidth: 3
            )
        )
        .foregroundStyle(.gray)
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
            primaryRow: aircraft.currentTrip != nil
                ? ListRow(trip: aircraft.currentTrip!) : nil,
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

    init(
        staff: Staff,
        onTapAction: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) {
        self.init(
            profileImage: staff.avatarImage,
            titleText: staff.name,
            subTitleText: staff.designation.rawValue,
            detailText: staff.email,
            statusBadge: .from(staffStatus: staff.currentStatus),
            primaryRow: staff.currentTrip != nil
                ? ListRow(trip: staff.currentTrip!) : nil,
            listData: staff.completedTrips.map { trip in
                ListRow(trip: trip)
            },
            showProfileImage: true,
            onActionButtonTapped: onTapAction,
            actionButtonTitle: actionButtonTitle ?? "Change Availability",
            currentTaskTitle: "Current Assignment",
            listDataTitle: "Trip history"
        )
    }
}

//MARK: Preview
#Preview("Staff") {
    NavigationStack {
        DetailView(
            profileImage: nil,
            titleText: "Sarah Johnson",
            subTitleText: "Senior Software Engineer",
            detailText: "hp@gmail.com",
            statusBadge: StatusBadge(
                label: "Active",
                backgroundColor: Color.onTime
            ),
            primaryRow: ListRow(
                profileImage: nil,
                title: "Implement User Authentication",
                subtitle:
                    "Create login and signup functionality with JWT tokens",
                status: StatusBadge(
                    label: "Cancelled",
                    backgroundColor: Color.tripStatusColor(for: .cancelled)
                )
            ),
            listData: [
                ListRow(
                    profileImage: nil,
                    title: "Design Database Schema",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database Schem",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database Sche",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database Sch",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Database ",
                    subtitle: "Complete"
                ),
                ListRow(
                    profileImage: nil,
                    title: "Design Databas",
                    subtitle: "Complete"
                ),
            ],
            showProfileImage: true,
            onActionButtonTapped: {}
        )
    }
}

//#Preview("Aircraft") {
//    let mockRoute = Route(name: "New York to London")
//    mockRoute.nodes = [
//        RouteNode(
//            plannedArrivalOffsetMinutes: 120,
//            airport: Airport(
//                code: "JFK",
//                name: "John F. Kennedy",
//                city: "New York",
//                country: "USA"
//            )
//        ),
//        RouteNode(
//            plannedArrivalOffsetMinutes: 480,
//            airport: Airport(
//                code: "LHR",
//                name: "London Heathrow",
//                city: "London",
//                country: "UK"
//            )
//        ),
//    ]
//
//    let mockTrip1 = Trip(
//        staff: [],
//        aircraft: Aircraft(
//            registrationNumber: "N12345",
//            type: "Boeing 737",
//            seatingCapacity: 180,
//            minimumStaffRequired: [:]
//        ),
//        nodeStatuses: [],
//        route: mockRoute,
//        scheduledDepartureTime: Date(),
//        flightNumber: "AA-100",
//        isCancelled: false
//    )
//    mockTrip1.isCompleted = true
//
//    let mockTrip2 = Trip(
//        staff: [],
//        aircraft: Aircraft(
//            registrationNumber: "N12345",
//            type: "Boeing 737",
//            seatingCapacity: 180,
//            minimumStaffRequired: [:]
//        ),
//        nodeStatuses: [],
//        route: mockRoute,
//        scheduledDepartureTime: Date().addingTimeInterval(-86400),
//        flightNumber: "AA-101",
//        isCancelled: false
//    )
//    mockTrip2.isCompleted = true
//
//    let mockCurrent = Trip(
//        staff: [],
//        aircraft: Aircraft(
//            registrationNumber: "N12345",
//            type: "Boeing 737",
//            seatingCapacity: 180,
//            minimumStaffRequired: [:]
//        ),
//        nodeStatuses: [],
//        route: mockRoute,
//        scheduledDepartureTime: Date().addingTimeInterval(3600),
//        flightNumber: "AA-102",
//        isCancelled: false
//    )
//
//    let mockAircraft = Aircraft(
//        registrationNumber: "N12345",
//        type: "Boeing 737",
//        seatingCapacity: 180,
//        minimumStaffRequired: [.pilot: 2, .coPilot: 1, .cabinCrew: 5]
//    )
//    mockAircraft.trips = [mockTrip1, mockTrip2, mockCurrent]
//    mockAircraft.currentTrip = mockCurrent
//
//     DetailView(aircraft: mockAircraft)
//}

#Preview {
    return UserDetailView()
        .environment(SessionManager.shared)
}
