import SwiftData
import SwiftUI

enum SortOrder: String, CaseIterable {
    case ascending = "Ascending"
    case descending = "Descending"
}

struct TripListView: View {

    var externalTrips: [Trip] = []

    @Query(sort: \Trip.scheduledDepartureTime, order: .forward) var trips:
        [Trip]

    @State private var selectedFilter: TripStatus? = nil
    @State private var selectedSort: TripSort = .departure
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if displayedTrips.isEmpty {
                    fallbackBackground
                } else {
                    List {
                        ForEach(displayedTrips, id: \.id) { trip in
                            NavigationLink(
                                destination: TripDetailView(trip: trip)
                            ) {
                                ListRow(trip: trip)
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            if externalTrips.count == 0 {
                toolbarFilterSortItem
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search by trip number"
        )
        .searchToolbarBehavior(.minimize)
    }
}

// MARK: Toolbar Item
extension TripListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Filter by") {
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

                Section("Sort by") {
                    ForEach(TripSort.allCases, id: \.self) { sort in
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
        if externalTrips.count != 0 {
            return externalTrips
        }

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

        let sorted = filtered.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .flightNumber {
                let comparison =
                    lhs.flightNumber.lowercased()
                    < rhs.flightNumber.lowercased()
                return isAscending ? comparison : !comparison
            } else {
                let comparison =
                    lhs.scheduledDepartureTime < rhs.scheduledDepartureTime
                return isAscending ? comparison : !comparison
            }
        }

        return sorted
    }
}

#Preview {
    NavigationStack {
        TripListView(externalTrips: [])
    }
}
