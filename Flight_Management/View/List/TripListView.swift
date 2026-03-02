import SwiftData
import SwiftUI

struct TripListView: View {

    var externalTrips: [Trip]? = nil
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
                    list
                        .scrollDismissesKeyboard(.immediately)
                        .listStyle(.insetGrouped)
                        .refreshable {
                            if externalTrips != nil { return }
                            await viewModel.loadInitial(
                                context: context,
                                filter: selectedFilter,
                                searchText: searchText
                            )
                        }
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
            .task {
                if externalTrips != nil { return }
                await viewModel.loadInitial(
                    context: context,
                    filter: selectedFilter,
                    searchText: searchText
                )
            }
            .onChange(of: selectedFilter) { _, newFilter in
                if externalTrips != nil { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: newFilter,
                        searchText: searchText
                    )
                }
            }
            .onChange(of: searchText) { _, newSearch in
                if externalTrips != nil { return }
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

extension TripListView {
    var list: some View {
        List {
            ForEach(displayedTrips, id: \.id) { trip in
                NavigationLink(
                    destination: TripDetailView(trip: trip)
                ) {
                    ListRow(trip: trip)
                }
                .onAppear {
                    if externalTrips != nil { return }
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
        var filtered: [Trip]

        if externalTrips != nil {
            filtered = externalTrips!
        } else {
            filtered = viewModel.items
        }

        // Apply in-memory filter on the currently loaded batch / external list
        if let status = selectedFilter {
            filtered = filtered.filter { $0.currentStatus == status }
        }

        let sorted = filtered.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .flightNumber {
                let comparison =
                lhs.flightNumber
                .localizedStandardCompare(rhs.flightNumber)
                == .orderedAscending
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
        TripListView(externalTrips: nil)
    }
}
