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
                                    Image(systemName: selectedSortOrder == .ascending ? "arrow.up" : "arrow.down")
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
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "person.3")
                .resizable()
                .opacity(0.15)
                .frame(maxWidth: 150, maxHeight: 100)
            Text("No Staff Data Available.")
                .opacity(0.25)
        }
    }

    var displayedRoutes: [Route] {
        return routes.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending
            
            if selectedSort == .name {
                let comparison = lhs.name.lowercased() < rhs.name.lowercased()
                return isAscending ? comparison : !comparison
            } else {
                let comparison = lhs.trips.count < rhs.trips.count
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
