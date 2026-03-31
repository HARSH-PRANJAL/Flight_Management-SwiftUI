import SwiftData
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

private enum AdminDetailRoute: Hashable {
    case trip(UUID)
    case staff(UUID)
    case aircraft(UUID)
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
    @State private var selectedStaff: Staff?
    @State private var selectedRoute: Route?
    @State private var staffDetailPath: [AdminDetailRoute] = []
    @State private var routeDetailPath: [AdminDetailRoute] = []


    var body: some View {
        if selectedTab.usesThreeColumns {
            threeColumnSplit
                .id(selectedTab)
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
                StaffListView(selection: $selectedStaff)

            case .route:
                RouteListView(selection: $selectedRoute)

            default:
                EmptyView()
            }
        } detail: {
            NavigationStack(path: currentDetailPathBinding) {
                switch selectedTab {
                case .staff:
                    if let staff = selectedStaff {
                        StaffDetailView(
                            staff: staff,
                            onShowTrip: showTrip
                        )
                            .id(staff.id)
                    } else {
                        ContentUnavailableView(
                            "No Staff Selected",
                            systemImage: "person.2.fill",
                            description: Text(
                                "Select a staff member from the list."
                            )
                        )
                    }
                case .route:
                    if let route = selectedRoute {
                        RouteDetailView(
                            route: route,
                            onShowTrip: showTrip
                        )
                            .id(route.id)
                    } else {
                        ContentUnavailableView(
                            "No Route Selected",
                            systemImage: "map.fill",
                            description: Text("Select a route from the list.")
                        )
                    }
                default:
                    EmptyView()
                }
            }
            .navigationDestination(for: AdminDetailRoute.self) { destination in
                switch destination {
                case .trip(let id):
                    if let trip = trip(for: id) {
                        TripDetailView(
                            trip: trip,
                            onShowAircraft: showAircraft,
                            onShowStaff: showStaff
                        )
                    } else {
                        ContentUnavailableView("Trip Not Found", systemImage: "airplane.departure")
                    }
                case .staff(let id):
                    if let staff = staff(for: id) {
                        StaffDetailView(
                            staff: staff,
                            onShowTrip: showTrip
                        )
                    } else {
                        ContentUnavailableView("Staff Not Found", systemImage: "person.2.fill")
                    }
                case .aircraft(let id):
                    if let aircraft = aircraft(for: id) {
                        AircraftDetailView(
                            aircraft: aircraft
                        )
                    } else {
                        ContentUnavailableView("Aircraft Not Found", systemImage: "airplane")
                    }
                }
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
                selectedTab = newValue
            } else {
                sidebarSelection = selectedTab
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            sidebarSelection = newValue
        }
        .onChange(of: selectedStaff?.id) { _, newValue in
            if newValue != nil {
                staffDetailPath = []
            }
        }
        .onChange(of: selectedRoute?.id) { _, newValue in
            if newValue != nil {
                routeDetailPath = []
            }
        }
    }

    private func showTrip(_ trip: Trip) {
        switch selectedTab {
        case .staff:
            staffDetailPath.append(.trip(trip.id))
        case .route:
            routeDetailPath.append(.trip(trip.id))
        default:
            break
        }
    }

    private func showAircraft(_ aircraft: Aircraft) {
        switch selectedTab {
        case .staff:
            staffDetailPath.append(.aircraft(aircraft.id))
        case .route:
            routeDetailPath.append(.aircraft(aircraft.id))
        default:
            break
        }
    }

    private func showStaff(_ staff: Staff) {
        switch selectedTab {
        case .staff:
            staffDetailPath.append(.staff(staff.id))
        case .route:
            routeDetailPath.append(.staff(staff.id))
        default:
            break
        }
    }

    private func trip(for id: UUID) -> Trip? {
        var descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func staff(for id: UUID) -> Staff? {
        var descriptor = FetchDescriptor<Staff>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func aircraft(for id: UUID) -> Aircraft? {
        var descriptor = FetchDescriptor<Aircraft>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    private var currentDetailPathBinding: Binding<[AdminDetailRoute]> {
        switch selectedTab {
        case .staff:
            return $staffDetailPath
        case .route:
            return $routeDetailPath
        default:
            return $staffDetailPath
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
                HStack {
                    ToolbarLabel()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .padding(.trailing, 4)
                    Text("\(session.user?.name ?? "Admin")")
                        .foregroundStyle(Color.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 32)

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
