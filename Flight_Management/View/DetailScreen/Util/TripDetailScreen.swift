import SwiftData
import SwiftUI

struct TripDetailScreen: View {
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notification
    @Environment(\.dismiss) var dismiss

    @State private var isEditPresented = false
    @State private var selectedTab: DetailAirportTab = .detail
    @State private var previousTab: DetailAirportTab = .detail
    @State private var slideFromRight = true

    let trip: Trip
    var onCancelTapped: (() -> Void)? = nil
    var isTripManager: Bool = false

    var canCancelTrip: Bool {
        !trip.isCancelled && !trip.isCompleted && onCancelTapped != nil
    }

    var canEditTrip: Bool {
        trip.currentStatus == .scheduled && isTripManager
    }

    var tripHasStarted: Bool {
        !trip.nodeStatuses.isEmpty
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Group {
                        switch selectedTab {
                        case .detail:
                            detailView
                        case .legDetail:
                            AirportStatusListView(trip: trip)
                                .padding(.top, -20)
                        }
                    }
                    .id(selectedTab)
                    .transition(
                        .asymmetric(
                            insertion: .move(
                                edge: slideFromRight ? .trailing : .leading
                            ),
                            removal: .move(
                                edge: slideFromRight ? .leading : .trailing
                            )
                        )
                    )
                }
            }
            .animation(.snappy(duration: 0.35), value: selectedTab)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    detailScreenPicker(selectedTab: $selectedTab)
                        .onChange(of: selectedTab) { oldValue, newValue in
                            slideFromRight =
                                newValue.rawValue < oldValue.rawValue
                            previousTab = oldValue
                        }
                }
            }
            .sheet(isPresented: $isEditPresented) {
                NavigationStack {
                    TripRegistrationForm(
                        trip: trip,
                        isPresented: $isEditPresented
                    )
                }
            }
        }
    }
}

// MARK: UI
extension TripDetailScreen {

    var detailView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Section {
                        primaryCard
                    }

                    if canCancelTrip {
                        Section {
                            Button {
                                onCancelTapped?()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle")
                                        .font(.body.weight(.semibold))
                                    Text("Cancel Trip")
                                        .font(.body.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(.systemRed))
                        }
                    }

                    Section {
                        HStack(spacing: 12) {
                            CardView(
                                title: "Duration",
                                value:
                                    "\(trip.route.totalPlannedDurationMinutes) m",
                                icon: "clock",
                                iconColor: Color(.systemBrown)
                            )
                            CardView(
                                title: "Crew",
                                value: "\(trip.staffs.count)",
                                icon: "person.2",
                                iconColor: Color(.systemIndigo)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    proxy.scrollTo("staffSection", anchor: .top)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)

                    assignedAircraft
                        .padding(.bottom, 8)

                    if !trip.staffs.isEmpty {
                        assignedStaffList
                            .id("staffSection")
                    }
                }
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 16)
            .toolbar {
                if canEditTrip {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isEditPresented = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
        }
    }

    var assignedAircraft: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Aircraft")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "airplane.cloud")
                    .font(.subheadline)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(Color(.systemBlue))
            }
            NavigationLink(
                destination: AircraftDetailView(
                    aircraft: trip.aircraft
                )
            ) {
                HStack {
                    ListRow(tripAircraft: trip.aircraft)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.smallCaps())
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.trailing, 12)
                }
                .padding(16)
            }
            .buttonStyle(PressableRowStyle())
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemCyan))
                .padding(.bottom, 16)

            Text(trip.tripNumber)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            let origin =
                trip.route.nodes.first(where: { $0.sequence == 1 })?.airport
                .code
                ?? "_"
            let dest =
                trip.route.nodes.last(where: {
                    $0.sequence == trip.route.nodes.count
                })?
                .airport.code
                ?? "_"
            Text("\(origin) - \(dest)")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.bottom, 12)

            StatusCapsuleView(
                statusBadge: StatusBadge.from(tripStatus: trip.currentStatus)
            )
            .padding(.bottom, 16)

            Divider()
                .opacity(0.75)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 10) {
                if !trip.nodeStatuses.isEmpty
                    || trip.currentStatus == .scheduled
                {
                    DetailRowView(
                        label: "Departure",
                        value: formatDate(
                            trip.actualDepartureTime
                                ?? trip.scheduledDepartureTime,
                            format: "dd MMM yyyy, HH:mm"
                        )
                    )
                }
                if !trip.isCancelled {
                    DetailRowView(
                        label: trip.isCompleted
                            ? "Arrival" : "Estimated Arrival",
                        value: formatDate(
                            trip.estimatedArrivalTime,
                            format: "dd MMM yyyy, HH:mm"
                        )
                    )
                }
                if trip.totalDelayedMinutes > 0 {
                    DetailRowView(
                        label: "Delayed by",
                        value: "\(trip.totalDelayedMinutes) m"
                    )
                }

                DetailRowView(label: "Route", value: trip.route.name)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardTheme())
    }

    @ViewBuilder
    var assignedStaffList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Crew")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "person.2")
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemBlue))
            }

            VStack(spacing: 0) {
                ForEach(crew, id: \.id) { staff in

                    NavigationLink(
                        destination: StaffDetailView(staff: staff)
                    ) {
                        HStack {
                            ListRow(tripStaff: staff)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline.smallCaps())
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.trailing, 12)
                        }
                        .padding(16)
                    }
                    .buttonStyle(PressableRowStyle())
                    if staff.id != trip.staffs.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 16)
    }
}

// MARK: Util
extension TripDetailScreen {
    private var crew: [Staff] {
        return trip.staffs.sorted { staff1, staff2 in
            func priority(for designation: StaffRole) -> Int {
                switch designation {
                case .pilot:
                    return 0
                case .coPilot:
                    return 1
                case .cabinCrew:
                    return 2
                }
            }

            return priority(for: staff1.designation)
                < priority(for: staff2.designation)
        }
    }
}
