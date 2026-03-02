import SwiftData
import SwiftUI

struct TripList: View {

    var externalTrips: [Trip] = []
    var navigationTitle: String = "Trip List"
    var requiredFilters: [TripStatus] = TripStatus.allCases
    var isCountRequired: Bool = false

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
                    list
                        .scrollDismissesKeyboard(.immediately)
                        .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                toolbarFilterSortItem
            }
            .searchable(
                text: $searchText,
                placement: .toolbar,
                prompt: "Search by trip number or route name"
            )
            .searchToolbarBehavior(.minimize)
        }
    }
}

extension TripList {
    var list: some View {
        List {
            ForEach(displayedTrips, id: \.id) { trip in
                NavigationLink(
                    destination: TripDetailView(trip: trip)
                ) {
                    ListRow(trip: trip)
                }
            }

            if displayedTrips.count > 5 && isCountRequired {
                Text("\(displayedTrips.count) trips")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .scaledToFit()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: 50,
                        alignment: .center
                    )
                    .padding(.vertical, 8)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: Toolbar Item
extension TripList {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if !requiredFilters.isEmpty {
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
                                requiredFilters,
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
extension TripList {

    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Trips", systemImage: "airplane.departure")
        } description: {
            Text("Add or assign trips to see them here.")
        }
    }

    var displayedTrips: [Trip] {
        var filtered = externalTrips

        if let status = selectedFilter {
            filtered = filtered.filter { $0.currentStatus == status }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { trip in
                let flightMatch = trip.flightNumber
                    .localizedCaseInsensitiveContains(searchText)
                let routeMatch = trip.route.name
                    .localizedCaseInsensitiveContains(searchText)
                return flightMatch || routeMatch
            }
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
