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
                                searchText: searchText,
                                sort: selectedSort,
                                sortOrder: selectedSortOrder
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
                    searchText: searchText,
                    sort: selectedSort,
                    sortOrder: selectedSortOrder
                )
            }
            .onChange(of: selectedFilter) { _, newFilter in
                if externalTrips != nil { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: newFilter,
                        searchText: searchText,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                }
            }
            .onChange(of: searchText) { _, newSearch in
                if externalTrips != nil { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: newSearch,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                }
            }
            .onChange(of: selectedSort) { _, _ in
                if externalTrips != nil { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: searchText,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                }
            }
            .onChange(of: selectedSortOrder) { _, _ in
                if externalTrips != nil { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: searchText,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
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
                                searchText: searchText,
                                sort: selectedSort,
                                sortOrder: selectedSortOrder
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

// MARK: Fallback and Displayed Data
extension TripListView {

    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Trips", systemImage: "airplane.departure")
        } description: {
            Text("Add or assign trips to see them here.")
        }
    }

    var displayedTrips: [Trip] {
        guard let external = externalTrips else {
            return viewModel.items
        }

        var filtered = external
        if let status = selectedFilter {
            filtered = filtered.filter { $0.currentStatus == status }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { trip in
                trip.flightNumber.localizedCaseInsensitiveContains(searchText)
                    || trip.route.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { lhs, rhs in
            let asc = selectedSortOrder == .ascending
            return asc
                ? lhs.scheduledDepartureTime < rhs.scheduledDepartureTime
                : lhs.scheduledDepartureTime > rhs.scheduledDepartureTime
        }
    }
}
