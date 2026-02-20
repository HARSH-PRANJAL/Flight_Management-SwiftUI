import SwiftData
import SwiftUI

struct StaffDetailScreen: View {
    let staff: Staff
    var isAdmin: Bool = false

    var onActionButtonTapped: (() -> Void)? = nil
    @State private var showImagePreview = false
    @State private var selectedTab: Tab = .detail
    @Binding var isEditPageShowing: Bool

    enum Tab: String, CaseIterable {
        case detail = "Detail"
        case tripDetail = "Trip Detail"
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if staff.completedTrips.isEmpty {
                    detailView
                } else {
                    switch selectedTab {
                    case .detail:
                        detailView
                    case .tripDetail:
                        tripHistoryContent
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !staff.completedTrips.isEmpty {
                        Picker("View Mode", selection: $selectedTab) {
                            ForEach(Tab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .animation(.linear(duration: 0.5), value: selectedTab)
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = staff.avatarImage {
                ImagePreviewModal(
                    image: image,
                    title: "Profile Photo",
                    circular: true
                )
            } else {
                EmptyView()
            }
        }
    }

    var detailView: some View {
        ScrollView {
            VStack(spacing: 16) {
                primaryCard

                if onActionButtonTapped != nil {
                    actionButton
                }

                HStack {
                    CardView(
                        title: "Total Trips",
                        value: "\(staff.trips.count)",
                        subtitle: "",
                        icon: "airplane.up.right",
                        iconColor: Color(.white),
                        background: Color(.systemBlue)
                    )

                    CardView(
                        title: "Flight Hours",
                        value: String(format: "%.1f", staff.totalTripHours),
                        subtitle: "",
                        icon: "clock",
                        iconColor: Color(.white),
                        background: Color(.systemBrown)
                    )
                }

                flightSectionsCard
            }
            .padding(.horizontal, 16)
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
    }

    var flightSectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = staff.currentTrip {
                flightSection(
                    title: "Current Flight",
                    icon: "clock.badge.airplane",
                    iconColor: Color(.systemCyan),
                    trip: trip
                )
            }
            if let trip = staff.nextScheduledTrip {
                flightSection(
                    title: "Next Flight",
                    icon: "calendar.badge.clock",
                    iconColor: Color(.systemIndigo),
                    trip: trip
                )
            }
            if let trip = staff.lastCompletedTrip {
                flightSection(
                    title: "Last Flight",
                    icon: "checkmark.circle",
                    iconColor: Color(.systemGreen),
                    trip: trip
                )
            }
        }
        .padding(.bottom, 16)
    }

    func flightSection(
        title: String,
        icon: String,
        iconColor: Color,
        trip: Trip
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }

            HStack {
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    ListRow(trip: trip)
                }
                .buttonStyle(.plain)
                .padding(12)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.smallCaps())
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.trailing, 12)
            }
            .background(cardTheme())
        }
    }

    var tripHistoryContent: some View {
        TripListView(externalTrips: staff.trips, navigationTitle: "")
    }

    var actionButton: some View {
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
            .foregroundStyle(
                staff.isMarkedUnavailable
                    ? Color(.systemGreen) : Color(.systemRed)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardTheme())
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        staff.isMarkedUnavailable
                            ? Color(.systemGreen).opacity(0.4)
                            : Color(.systemRed).opacity(0.4),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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

#Preview {
    NavigationStack {
        StaffDetailScreen(
            staff: Staff(
                name: "Captain John Doe",
                designation: .pilot,
                gender: .male,
                email: "john@example.com",
                dob: Date()
            ),
            isEditPageShowing: .constant(false)
        )
    }
}
