import SwiftUI
import SwiftData

struct TripListView: View {

    @Query(sort: \Trip.scheduledDepartureTime, order: .forward) var trips: [Trip]

    @State private var selectedFilter: TripStatus? = nil
    @State private var selectedSort: TripSort = .departure
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            Group {
                if displayedTrips.isEmpty {
                    fallbackBackground
                } else {
                    List {
                        ForEach(displayedTrips, id: \.id) { trip in
                            NavigationLink(destination: DetailView(trip: trip)) {
                                ListRow(trip: trip)
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
                prompt: "Search by flight number or route"
            )
            .searchToolbarBehavior(.minimize)
        }
    }
}

// MARK: Toolbar Item
extension TripListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Filter") {
                    VStack(spacing: 0) {
                        Button {
                            selectedFilter = nil
                        } label: {
                            HStack {
                                Text("All")
                                if selectedFilter == nil {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        ForEach(
                            TripStatus.allCases,
                            id: \.self
                        ) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                HStack {
                                    Text(filter.rawValue)
                                    if selectedFilter == filter {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                Divider()
                Section("Sort by") {
                    ForEach(TripSort.allCases, id: \.self) { sort in
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
extension TripListView {
    var fallbackBackground: some View {
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "airplane")
                .resizable()
                .opacity(0.15)
                .frame(maxWidth: 150, maxHeight: 100)
            Text("No Trip Data Available.")
                .opacity(0.25)
        }
    }

    var displayedTrips: [Trip] {
        var filtered = trips.filter { trip in
            if selectedFilter == nil {
                return true
            } else {
                return trip.currentStatus == selectedFilter
            }
        }

        filtered = filtered.filter { trip in
            if searchText.isEmpty { return true }

            let flightMatch = trip.flightNumber
                .localizedCaseInsensitiveContains(searchText)

            let routeMatch = trip.route.name
                .localizedCaseInsensitiveContains(searchText)

            return flightMatch || routeMatch
        }

        return filtered.sorted { lhs, rhs in
            if selectedSort == .flightNumber {
                return lhs.flightNumber.lowercased() < rhs.flightNumber.lowercased()
            } else {
                return lhs.scheduledDepartureTime < rhs.scheduledDepartureTime
            }
        }
    }
}

#Preview {
    NavigationStack {
        TripListView()
    }
}
