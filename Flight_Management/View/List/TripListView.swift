import SwiftData
import SwiftUI

struct TripListView: View {

    var externalTrips: [Trip] = []
    var navigationTitle: String = "Trip List"
    var requiredFilters: [TripStatus] = TripStatus.allCases

    @Environment(\.modelContext) private var context

    @State private var viewModel = TripListViewModel()

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
                            .onAppear {
                                guard externalTrips.isEmpty else { return }
                                if trip.id == displayedTrips.last?.id {
                                    Task {
                                        await viewModel.loadMore(
                                            context: context,
                                            filter: selectedFilter,
                                            searchText: searchText
                                        )
                                    }
                                }
                            }
                        }
                    }
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
                prompt: "Search by trip number"
            )
            .searchToolbarBehavior(.minimize)
            .task {
                guard externalTrips.isEmpty else { return }
                await viewModel.loadInitial(
                    context: context,
                    filter: selectedFilter,
                    searchText: searchText
                )
            }
            .onChange(of: selectedFilter) { _, newFilter in
                guard externalTrips.isEmpty else { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: newFilter,
                        searchText: searchText
                    )
                }
            }
            .onChange(of: searchText) { _, newSearch in
                guard externalTrips.isEmpty else { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: newSearch
                    )
                }
            }
        }
    }
}

// MARK: Toolbar Item
extension TripListView {

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
extension TripListView {

    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Trips", systemImage: "airplane.departure")
        } description: {
            Text("Add or assign trips to see them here.")
        }
    }

    var displayedTrips: [Trip] {
        var filtered: [Trip] =
            externalTrips.isEmpty
            ? viewModel.items
            : externalTrips

        // Apply in-memory filter on the currently loaded batch / external list
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

#Preview {
    NavigationStack {
        TripListView(externalTrips: [])
    }
}
