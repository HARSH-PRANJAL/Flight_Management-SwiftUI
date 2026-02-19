import SwiftData
import SwiftUI

struct RouteListView: View {

    @Query var routes: [Route]

    @State private var selectedSort: RouteSort = .name
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            Group {
                if displayedRoutes.isEmpty {
                    fallbackBackground
                } else {
                    List {
                        ForEach(displayedRoutes, id: \.id) { route in
                            NavigationLink(destination: RouteDetailView(route: route)) {
                                ListRow(route: route)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Route List")
            .toolbar {
                toolbarFilterSortItem
            }
            .searchable(
                text: $searchText,
                prompt: "Search by name or flight number"
            )
            .searchToolbarBehavior(.minimize)
        }
    }
}

// MARK: Toolbar Item
extension RouteListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Sort by") {
                    ForEach(RouteSort.allCases, id: \.self) { sort in
                        Button {
                            if selectedSort == sort {
                                // Toggle sort order if same option clicked
                                selectedSortOrder = selectedSortOrder == .ascending ? .descending : .ascending
                            } else {
                                // Select new sort option
                                selectedSort = sort
                                selectedSortOrder = .ascending
                            }
                        } label: {
                            HStack {
                                Text(sort.rawValue)
                                Spacer()
                                if selectedSort == sort {
                                    Image(
                                        systemName: selectedSortOrder
                                            == .ascending
                                            ? "arrow.up" : "arrow.down"
                                    )
                                    .foregroundStyle(Color(.systemBlue))
                                }
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }
    }
}

// MARK: Fallback and Filter Data
extension RouteListView {
    var fallbackBackground: some View {
        ContentUnavailableView {
            Label(
                "No Routes",
                systemImage:
                    "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath"
            )
        } description: {
            Text("Add routes to get started.")
        }
    }

    var displayedRoutes: [Route] {
        var filtered = routes

        if !searchText.isEmpty {
            let cleanSearchText =
                searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if !cleanSearchText.isEmpty {
                filtered = routes.filter { route in
                    let nameMatch = route.name
                        .lowercased()
                        .contains(cleanSearchText)

                    let airportMatch = route.nodes.contains { node in
                        node.airport.code.lowercased().contains(cleanSearchText)
                            || node.airport.name.lowercased().contains(
                                cleanSearchText
                            )
                            || node.airport.city.lowercased().contains(
                                cleanSearchText
                            )
                    }

                    return nameMatch || airportMatch
                }
            }
        }

        return filtered.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .name {
                let comparison =
                    lhs.name.localizedStandardCompare(rhs.name)
                    == .orderedAscending
                return isAscending ? comparison : !comparison
            } else {
                let comparison = lhs.trips.count <= rhs.trips.count
                return isAscending ? comparison : !comparison
            }
        }
    }
}

#Preview {
    NavigationStack {
        RouteListView()
    }
}
