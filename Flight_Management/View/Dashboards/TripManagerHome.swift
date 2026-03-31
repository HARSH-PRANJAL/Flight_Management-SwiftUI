import SwiftData
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
        self == .aircrafts || self == .trips || self == .routes
    }
}

private enum TripManagerDetailRoute: Hashable {
    case trip(UUID)
    case staff(UUID)
    case aircraft(UUID)
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
    @State private var selectedRoute: Route?
    @State private var aircraftDetailPath: [TripManagerDetailRoute] = []
    @State private var tripDetailPath: [TripManagerDetailRoute] = []
    @State private var routeDetailPath: [TripManagerDetailRoute] = []

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
            case .routes:
                NavigationStack {
                    RouteListView(selection: $selectedRoute)
                }
            default:
                EmptyView()
            }
        } detail: {
            NavigationStack(path: currentDetailPathBinding) {
                switch selectedTab {
                case .aircrafts:
                    if let aircraft = selectedAircraft {
                        AircraftDetailView(
                            aircraft: aircraft,
                            onShowTrip: showTrip
                        )
                    } else {
                        ContentUnavailableView(
                            "No Aircraft Selected",
                            systemImage: "airplane",
                            description: Text(
                                "Select an aircraft from the list."
                            )
                        )
                    }
                case .trips:
                    if let trip = selectedTrip {
                        TripDetailView(
                            trip: trip,
                            onShowAircraft: showAircraft,
                            onShowStaff: showStaff
                        )
                    } else {
                        ContentUnavailableView(
                            "No Trip Selected",
                            systemImage: "airplane.departure",
                            description: Text("Select a trip from the list.")
                        )
                    }
                case .routes:
                    if let route = selectedRoute {
                        RouteDetailView(
                            route: route,
                            onShowTrip: showTrip
                        )
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
            .navigationDestination(for: TripManagerDetailRoute.self) { destination in
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
                            aircraft: aircraft,
                            onShowTrip: showTrip
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
                    TripManagerDashboardView()
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
        .onChange(of: selectedAircraft?.id) { _, newValue in
            if newValue != nil {
                aircraftDetailPath = []
            }
        }
        .onChange(of: selectedTrip?.id) { _, newValue in
            if newValue != nil {
                tripDetailPath = []
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
        case .aircrafts:
            aircraftDetailPath.append(.trip(trip.id))
        case .trips:
            tripDetailPath.append(.trip(trip.id))
        case .routes:
            routeDetailPath.append(.trip(trip.id))
        default:
            break
        }
    }

    private func showAircraft(_ aircraft: Aircraft) {
        switch selectedTab {
        case .aircrafts:
            aircraftDetailPath.append(.aircraft(aircraft.id))
        case .trips:
            tripDetailPath.append(.aircraft(aircraft.id))
        case .routes:
            routeDetailPath.append(.aircraft(aircraft.id))
        default:
            break
        }
    }

    private func showStaff(_ staff: Staff) {
        switch selectedTab {
        case .aircrafts:
            aircraftDetailPath.append(.staff(staff.id))
        case .trips:
            tripDetailPath.append(.staff(staff.id))
        case .routes:
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

    private func route(for id: UUID) -> Route? {
        var descriptor = FetchDescriptor<Route>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    private var currentDetailPathBinding: Binding<[TripManagerDetailRoute]> {
        switch selectedTab {
        case .aircrafts:
            return $aircraftDetailPath
        case .trips:
            return $tripDetailPath
        case .routes:
            return $routeDetailPath
        default:
            return $tripDetailPath
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
                    Text("\(session.user?.name ?? "Manager")")
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
