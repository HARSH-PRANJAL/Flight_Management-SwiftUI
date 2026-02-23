import SwiftData
import SwiftUI

struct StaffDetailScreen: View {
    let staff: Staff
    var isAdmin: Bool = false

    var onActionButtonTapped: (() -> Void)? = nil
    @State private var showImagePreview = false
    @State private var selectedTab: DetailTab = .detail
    @Binding var isEditPageShowing: Bool

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
                    case .tripHistory:
                        tripHistoryContent
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !staff.completedTrips.isEmpty {
                        detailScreenPicker(selectedTab: $selectedTab)
                    }
                }
            }
        }
        .animation(.linear(duration: 0.5), value: selectedTab)
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = staff.avatarImage {
                ImagePreviewer(
                    image: image,
                    title: "Profile Photo",
                    circular: true,
                    profileBgColor: staff.profileBgColor
                )
            } else {
                EmptyView()
            }
        }
    }

    var detailView: some View {
        List {
            Section {
                primaryCard
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(cardTheme())
            .listRowSeparator(.hidden)

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
                        .foregroundStyle(
                            staff.isMarkedUnavailable
                                ? Color(.systemGreen) : Color(.systemRed)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    staff.isMarkedUnavailable
                                        ? Color(.systemGreen).opacity(0.4)
                                        : Color(.systemRed).opacity(0.4),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(
                        staff.isMarkedUnavailable
                            ? Color(.systemGreen).opacity(0.05) : Color(.systemRed).opacity(0.05)
                    )
                    .listRowSeparator(.hidden)
                }
            }

            Section {
                HStack(spacing: 12) {
                    CardView(
                        title: "Total Trips",
                        value: "\(staff.trips.count)",
                        subtitle: "",
                        icon: "airplane.up.right",
                        iconColor: Color(.systemBlue)
                    )
                    CardView(
                        title: "Flight Hours",
                        value: String(format: "%.1f", staff.totalTripHours),
                        subtitle: "",
                        icon: "clock",
                        iconColor: Color(.systemPurple)
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if let trip = staff.currentTrip {
                Section {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        ListRow(trip: trip)
                    }
                } header: {
                    Label("Current Flight", systemImage: "clock.badge.airplane")
                        .foregroundStyle(Color(.systemCyan))
                }
            }

            if let trip = staff.nextScheduledTrip {
                Section {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        ListRow(trip: trip)
                    }
                } header: {
                    Label("Next Flight", systemImage: "calendar.badge.clock")
                        .foregroundStyle(Color(.systemIndigo))
                }
            }

            if let trip = staff.lastCompletedTrip {
                Section {
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        ListRow(trip: trip)
                    }
                } header: {
                    Label("Last Flight", systemImage: "checkmark.circle")
                        .foregroundStyle(Color(.systemGreen))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
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
    var tripHistoryContent: some View {
        TripListView(externalTrips: staff.trips, navigationTitle: "")
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
