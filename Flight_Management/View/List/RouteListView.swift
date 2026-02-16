import SwiftData
import SwiftUI

struct RouteListView: View {

    @Query var routes: [Route]

    @State private var selectedSort: RouteSort = .name
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
                            selectedSort = sort
                        } label: {
                            HStack {
                                Text(sort.rawValue)
                                if selectedSort == sort {
                                    Spacer()
                                    Image(systemName: "checkmark")
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
            if selectedSort == .name {
                return lhs.name.lowercased() < rhs.name.lowercased()
            } else {
                return lhs.trips.count < rhs.trips.count
            }
        }
    }
}

#Preview {
    NavigationStack {
        RouteListView()
    }
}
