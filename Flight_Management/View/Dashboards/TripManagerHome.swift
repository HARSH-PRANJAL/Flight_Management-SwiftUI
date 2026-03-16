import SwiftUI

// MARK: Tab
enum TripManagerTab: String, CaseIterable, Hashable {
    case home = "Home"
    case aircrafts = "Aircrafts"
    case trips = "Trips"
    case routes = "Routes"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .aircrafts: return "airplane"
        case .routes: return "map.fill"
        case .trips: return "airplane.departure"
        case .profile: return "person.crop.circle"
        }
    }

    var usesThreeColumns: Bool {
        self == .aircrafts || self == .trips
    }
}

struct TripManagerHome: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab: TripManagerTab = .home

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                TripManagerSidebarHost(
                    selectedTab: $selectedTab
                )
            } else {
                TripManagerTabLayout(
                    selectedTab: $selectedTab
                )
            }
        }
    }
}

// MARK: iPad
private struct TripManagerSidebarHost: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notification

    @Binding var selectedTab: TripManagerTab

    @State private var sidebarSelection: TripManagerTab? = .home
    @State private var isTripRegistrationPresented: Bool = false
    @State private var selectedAircraft: Aircraft?
    @State private var selectedTrip: Trip?

    var body: some View {
        Group {
            if selectedTab.usesThreeColumns {
                threeColumnSplit
                    .id(selectedTab)
            } else {
                twoColumnSplit
            }
        }
        .sheet(isPresented: $isTripRegistrationPresented) {
            NavigationStack {
                TripRegistrationForm(isPresented: $isTripRegistrationPresented)
            }
        }
    }

    private var threeColumnSplit: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } content: {
            switch selectedTab {
            case .aircrafts:
                NavigationStack {
                    AircraftListView(selection: $selectedAircraft)
                }
            case .trips:
                NavigationStack {
                    TripListView(selection: $selectedTrip)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    isTripRegistrationPresented.toggle()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                }
            default:
                EmptyView()
            }
        } detail: {
            switch selectedTab {
            case .aircrafts:
                if let aircraft = selectedAircraft {
                    AircraftDetailView(aircraft: aircraft)
                } else {
                    ContentUnavailableView(
                        "No Aircraft Selected",
                        systemImage: "airplane",
                        description: Text("Select an aircraft from the list.")
                    )
                }
            case .trips:
                if let trip = selectedTrip {
                    TripDetailView(trip: trip)
                } else {
                    ContentUnavailableView(
                        "No Trip Selected",
                        systemImage: "airplane.departure",
                        description: Text("Select a trip from the list.")
                    )
                }
            default:
                EmptyView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var twoColumnSplit: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } detail: {
            switch selectedTab {
            case .home:
                NavigationStack {
                    TripManagerDashboardView()
                        .navigationTitle("Manager")
                        .toolbar {
                            profileHandlerToolbarItem(
                                session: session,
                                modelContext: modelContext
                            )
                        }
                }
            case .routes:
                NavigationStack {
                    RouteListView(requiredFilters: [], selectedFilter: .active)
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
            ForEach(TripManagerTab.allCases, id: \.self) { tab in
                if tab != .profile {
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
                selectedTab = newValue
            } else {
                sidebarSelection = selectedTab
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            sidebarSelection = newValue
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
private struct TripManagerTabLayout: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext

    @Binding var selectedTab: TripManagerTab

    @State private var isTripRegistrationPresented: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                TripManagerTab.home.rawValue,
                systemImage: TripManagerTab.home.icon,
                value: TripManagerTab.home
            ) {
                NavigationStack {
                    TripManagerDashboardView()
                        .navigationTitle("Manager")
                        .toolbar {
                            profileHandlerToolbarItem(
                                session: session,
                                modelContext: modelContext
                            )
                        }
                }
            }

            Tab(
                TripManagerTab.aircrafts.rawValue,
                systemImage: TripManagerTab.aircrafts.icon,
                value: TripManagerTab.aircrafts
            ) {
                NavigationStack {
                    AircraftListView()
                }
            }

            Tab(
                TripManagerTab.routes.rawValue,
                systemImage: TripManagerTab.routes.icon,
                value: TripManagerTab.routes
            ) {
                NavigationStack {
                    RouteListView(requiredFilters: [], selectedFilter: .active)
                }
            }

            Tab(
                TripManagerTab.trips.rawValue,
                systemImage: TripManagerTab.trips.icon,
                value: TripManagerTab.trips
            ) {
                NavigationStack {
                    TripListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    isTripRegistrationPresented.toggle()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $isTripRegistrationPresented) {
            NavigationStack {
                TripRegistrationForm(isPresented: $isTripRegistrationPresented)
            }
        }
    }
}
