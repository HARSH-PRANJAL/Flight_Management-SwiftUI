import SwiftUI

struct RouteList: View {

    let externalRoutes: [Route]
    var requiredFilters: [RouteStatus] = RouteStatus.allCases

    @State private var selectedSort: RouteSort = .name
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            Group {
                if displayedRoutes.isEmpty {
                    fallbackBackground
                } else {
                    list
                }
            }
            .toolbar {
                toolbarFilterSortItem
            }
            .searchable(
                text: $searchText,
                prompt: "Search by name"
            )
            .searchToolbarBehavior(.minimize)
        }
    }
}

// MARK: List
extension RouteList {

    var list: some View {
        List {
            ForEach(displayedRoutes, id: \.id) { route in
                Group {
                    NavigationLink(
                        destination: RouteDetailView(route: route)
                    ) {
                        ListRow(route: route)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .listStyle(.insetGrouped)
    }
}

// MARK: Toolbar Item
extension RouteList {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Sort by") {
                    ForEach(RouteSort.allCases, id: \.self) { sort in
                        Button {
                            if selectedSort == sort {
                                // Toggle sort order if same option clicked
                                selectedSortOrder =
                                    selectedSortOrder == .ascending
                                    ? .descending : .ascending
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
extension RouteList {
    var fallbackBackground: some View {
        ContentUnavailableView {
            Label(
                "",
                systemImage:
                    "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath"
            )
        } description: {
            Text("No active route with this name.")
        }
    }

    var displayedRoutes: [Route] {
        let sorted = externalRoutes.sorted { lhs, rhs in
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

        if !searchText.isEmpty {
            return sorted.filter {
                $0.nameSearchKey.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sorted
    }
}
