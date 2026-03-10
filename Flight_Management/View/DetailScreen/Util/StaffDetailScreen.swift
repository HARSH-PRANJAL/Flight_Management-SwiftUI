import SwiftData
import SwiftUI

struct StaffDetailScreen: View {
    let staff: Staff
    var isAdmin: Bool = false

    var onActionButtonTapped: (() -> Void)? = nil
    @State private var showImagePreview = false
    @State private var selectedTab: DetailTripTab = .detail
    @Binding var isScheduledTripsPresented: Bool
    @Binding var isEditPageShowing: Bool

    var tripHours: String {
        let hours = staff.totalTripHours

        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(hours))
        } else {
            return String(format: "%.1f", hours)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if staff.trips.isEmpty {
                    detailView
                } else {
                    switch selectedTab {
                    case .detail:
                        detailView
                    case .tripHistory:
                        tripContent
                    }
                }
            }
            .navigationTitle("\(staff.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !staff.trips.isEmpty {
                        detailScreenPicker(selectedTab: $selectedTab)
                    }
                }
            }
        }
        .animation(.linear(duration: 0.5), value: selectedTab)
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = staff.avatarImage {
                NavigationStack {
                    ImagePreviewer(
                        image: image,
                        title: "Profile Photo",
                        circular: true,
                        profileBgColor: staff.profileBgColor
                    )
                }
            } else {
                EmptyView()
            }
        }
    }

    var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Section {
                    primaryCard
                }

                if onActionButtonTapped != nil {
                    Section {
                        Button {
                            onActionButtonTapped!()
                        } label: {
                            HStack(spacing: 8) {
                                Image(
                                    systemName: staff.isMarkedUnavailable
                                        ? "person.badge.plus" : "person.slash"
                                )
                                .font(.body.weight(.semibold))
                                Text(
                                    staff.isMarkedUnavailable
                                        ? "Mark Available" : "Mark Unavailable"
                                )
                                .font(.body.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(
                            staff.isMarkedUnavailable
                                ? Color(.systemGreen)
                                : Color(.systemRed)
                        )
                        .padding(.bottom, 8)
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        CardView(
                            title: "Scheduled",
                            value: "\(staff.scheduledTrips.count)",
                            icon: "airplane.up.right",
                            iconColor: Color(.systemBlue)
                        )
                        .onTapGesture {
                            if !staff.scheduledTrips.isEmpty {
                                isScheduledTripsPresented.toggle()
                            }
                        }
                        CardView(
                            title: "Flying Hours",
                            value:
                                "\(tripHours) hr",
                            icon: "clock",
                            iconColor: Color(.systemPurple)
                        )
                    }
                    .padding(.bottom, 8)
                }

                flightSectionsCard
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .scrollIndicators(.hidden)
        .toolbar {
            if isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isEditPageShowing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }

    var tripContent: some View {
        TripList(
            externalTrips: staff.trips,
            navigationTitle: "\(staff.name) trips",
            requiredFilters: [.completed, .cancelled, .scheduled],
            isCountRequired: true
        )
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, -20)
    }
}

//MARK: UI
extension StaffDetailScreen {

    var flightSectionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let trip = staff.currentTrip {
                ClickableSection(
                    title: "Current Trip",
                    icon: "clock.badge.airplane",
                    iconColor: Color(.systemCyan),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
            if let trip = staff.nextScheduledTrip {
                ClickableSection(
                    title: "Next Trip",
                    icon: "calendar.badge.clock",
                    iconColor: Color(.systemIndigo),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
            if let trip = staff.lastCompletedTrip {
                ClickableSection(
                    title: "Last Trip",
                    icon: "checkmark.circle",
                    iconColor: Color(.systemGreen),
                    row: { ListRow(trip: trip) },
                    destination: { TripDetailView(trip: trip) }
                )
            }
        }
        .padding(.bottom, 16)
    }

    var primaryCard: some View {
        VStack(spacing: 0) {
            displayImage
                .padding(.bottom, 20)
            Text(staff.name)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            Text(staff.designation.rawValue)
                .font(.title2)
                .foregroundStyle(Color(.systemGray))
                .lineLimit(1)
                .padding(.bottom, 10)
            statusCapsule
                .padding(.bottom, 15)
            Divider()
                .padding(.bottom, 10)
                .opacity(0.75)
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Label {
                        TextWithCopyView(text: "\(staff.email)")
                    } icon: {
                        Image(systemName: "envelope.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                .white,
                                LinearGradient(
                                    colors: [
                                        Color(.systemPurple),
                                        Color(.systemPurple).opacity(0.75),
                                        Color(.systemPurple).opacity(0.5),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.bottom, -19)
                    Label {
                        Text("\(formatDate(staff.dob, format: "d MMM yyyy"))")
                            .font(.body)
                            .textSelection(.enabled)
                    } icon: {
                        Image(systemName: "calendar.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                .white,
                                LinearGradient(
                                    colors: [
                                        Color(.systemPink),
                                        Color(.systemPink).opacity(0.75),
                                        Color(.systemPink).opacity(0.5),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                Spacer()
            }

        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            cardTheme()
        )
    }

    var statusCapsule: some View {
        StatusCapsuleView(
            statusBadge: StatusBadge.from(staffStatus: staff.currentStatus)
        )
    }

    var displayImage: some View {
        Group {
            if let profileImage = staff.avatarImage {
                profileImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        showImagePreview = true
                    }
                    .hoverEffect(.highlight)
            } else {
                fallbackStaffImage()
                    .allowsHitTesting(false)
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color(.secondarySystemBackground), lineWidth: 3)
        )
        .foregroundStyle(.gray)
    }
}
