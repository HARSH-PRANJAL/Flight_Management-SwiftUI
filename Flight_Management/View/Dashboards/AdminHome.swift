import SwiftUI

// MARK: Tab
enum AdminTab: String, CaseIterable, Hashable {
    case home = "Home"
    case staff = "Staff"
    case route = "Route"
    case airports = "Airports"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .staff: return "person.2.fill"
        case .route: return "map.fill"
        case .airports: return "airplane.landed"
        case .profile: return "person.crop.fill"
        }
    }

    var usesThreeColumns: Bool {
        self == .staff || self == .route
    }

    var isBottomItem: Bool {
        self == .profile
    }
}

struct AdminHome: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab: AdminTab = .home

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                AdminSidebarHost(
                    selectedTab: $selectedTab
                )
            } else {
                AdminTabLayout(
                    selectedTab: $selectedTab
                )
            }
        }
    }
}

// MARK: iPad
private struct AdminSidebarHost: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notification

    @Binding var selectedTab: AdminTab

    @State private var sidebarSelection: AdminTab? = .home

    var body: some View {
        if selectedTab.usesThreeColumns {
            threeColumnSplit
        } else {
            twoColumnSplit
        }
    }

    private var threeColumnSplit: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } content: {
            switch selectedTab {
            case .staff:
                StaffListView()

            case .route:
                RouteListView()

            default:
                EmptyView()
            }
        } detail: {
            switch selectedTab {
            case .staff:
                ContentUnavailableView(
                    "No Staff Selected",
                    systemImage: "person.2.fill",
                    description: Text("Select a staff member from the list.")
                )
            case .route:
                ContentUnavailableView(
                    "No Route Selected",
                    systemImage: "map.fill",
                    description: Text("Select a route from the list.")
                )
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .navigationSplitViewStyle(.balanced)
    }

    private var twoColumnSplit: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } detail: {
            switch selectedTab {
            case .home:
                NavigationStack {
                    AdminDashboardView()
                }
            case .airports:
                NavigationStack {
                    AirportListView()
                }
            case .profile:
                NavigationStack {
                    UserDetailView()
                }
            default:
                EmptyView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            Section {
                ForEach(
                    AdminTab.allCases.filter { !$0.isBottomItem },
                    id: \.self
                ) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            sideBarBottomSection
        }
        .listStyle(.sidebar)

        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        .onChange(of: sidebarSelection) { _, newValue in
            if let newValue {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = newValue
                }
            } else {
                sidebarSelection = selectedTab
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) {
                sidebarSelection = newValue
            }
        }
    }

    var sideBarBottomSection: some View {
        VStack(alignment: .leading, spacing: 0) {

            Divider().opacity(0.75).padding(.bottom, 16)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    sidebarSelection = .profile
                    selectedTab = .profile
                }
            } label: {
                HStack(spacing: 10) {
                    ToolbarLabel()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    Text("Profile")
                        .foregroundStyle(
                            sidebarSelection == .profile
                                ? Color(.systemBlue)
                                : Color(.label)
                        )

                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .background(
                Capsule()
                    .fill(
                        sidebarSelection == .profile
                            ? Color(.systemGray5)
                            : Color.clear
                    )
            )
            .padding(.horizontal, 16)

            // Logout row
            Button(role: .destructive) {
                session.logout()
                notification.showSuccess("Logged out successfully.")
            } label: {
                Label(
                    "Logout",
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
                .foregroundStyle(Color(.systemRed))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 32)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
        }
        .background(.bar)
    }
}

// MARK: iOS
private struct AdminTabLayout: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext

    @Binding var selectedTab: AdminTab

    var body: some View {
        TabView(selection: $selectedTab) {

            Tab(
                AdminTab.home.rawValue,
                systemImage: AdminTab.home.icon,
                value: AdminTab.home
            ) {
                NavigationStack {
                    AdminDashboardView()
                        .toolbar {
                            profileHandlerToolbarItem(
                                session: session,
                                modelContext: modelContext
                            )
                        }
                }
            }

            Tab(
                AdminTab.staff.rawValue,
                systemImage: AdminTab.staff.icon,
                value: AdminTab.staff
            ) {
                NavigationStack {
                    StaffListView()
                }
            }

            Tab(
                AdminTab.route.rawValue,
                systemImage: AdminTab.route.icon,
                value: AdminTab.route
            ) {
                NavigationStack {
                    RouteListView()
                }
            }

            Tab(
                AdminTab.airports.rawValue,
                systemImage: AdminTab.airports.icon,
                value: AdminTab.airports
            ) {
                NavigationStack {
                    AirportListView()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
