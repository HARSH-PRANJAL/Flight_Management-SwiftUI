import SwiftData
import SwiftUI

struct AircraftListView: View {

    @Environment(\.modelContext) private var context

    @State private var viewModel = AircraftListViewModel()

    @State private var selectedStatus: AircraftStatus? = nil
    @State private var selectedSort: AircraftSort = .registration
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""
    @State private var showAircraftRegistration: Bool = false
    @State private var selectedAircraft: Aircraft?

    var body: some View {
        Group {
            if displayedAircrafts.isEmpty {
                fallbackBackground
            } else {
                List {
                    ForEach(displayedAircrafts, id: \.id) { aircraft in
                        NavigationLink(
                            destination: AircraftDetailView(aircraft: aircraft)
                        ) {
                            ListRow(aircraft: aircraft)
                        }
                        .onAppear {
                            if aircraft.id == displayedAircrafts.last?.id {
                                Task {
                                    await viewModel.loadMore(
                                        context: context,
                                        statusFilter: selectedStatus,
                                        searchText: searchText
                                    )
                                }
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .listStyle(.insetGrouped)
                .refreshable {
                    Task {
                        await viewModel.loadInitial(
                            context: context,
                            statusFilter: selectedStatus,
                            searchText: ""
                        )
                    }
                }
            }
        }
        .navigationTitle("Aircraft List")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAircraftRegistration.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
            toolbarFilterSortItem
        }
        .searchable(
            text: $searchText,
            prompt: "Search by registration"
        )
        .searchToolbarBehavior(.minimize)
        .task {
            await viewModel.loadInitial(
                context: context,
                statusFilter: selectedStatus,
                searchText: searchText
            )
        }
        .onChange(of: searchText) { _, newSearch in
            Task {
                await viewModel.loadInitial(
                    context: context,
                    statusFilter: selectedStatus,
                    searchText: newSearch
                )
            }
        }
        .sheet(isPresented: $showAircraftRegistration) {
            NavigationStack {
                AircraftRegistrationContent(
                    isPresented: $showAircraftRegistration
                )
            }
        }
    }
}

// MARK: Toolbar Item
extension AircraftListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Filter by") {
                    Button {
                        selectedStatus = nil
                        Task {
                            await viewModel.loadInitial(
                                context: context,
                                statusFilter: selectedStatus,
                                searchText: searchText
                            )
                        }
                    } label: {
                        HStack {
                            Text("All")
                            if selectedStatus == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Button {
                        selectedStatus = .available
                        Task {
                            await viewModel.loadInitial(
                                context: context,
                                statusFilter: selectedStatus,
                                searchText: searchText
                            )
                        }
                    } label: {
                        HStack {
                            Text("Available")
                            if selectedStatus == .available {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Button {
                        selectedStatus = .assigned
                        Task {
                            await viewModel.loadInitial(
                                context: context,
                                statusFilter: selectedStatus,
                                searchText: searchText
                            )
                        }
                    } label: {
                        HStack {
                            Text("Assigned")
                            if selectedStatus == .assigned {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Section("Sort by") {
                    ForEach(AircraftSort.allCases, id: \.self) { sort in
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
extension AircraftListView {
    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Aircraft", systemImage: "airplane")
        } description: {
            Text("Add aircraft to get started.")
        }
    }

    var displayedAircrafts: [Aircraft] {
        let sorted = viewModel.items.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .registration {
                let comparison =
                    lhs.registrationNumber
                    .localizedStandardCompare(rhs.registrationNumber)
                    == .orderedAscending
                return isAscending ? comparison : !comparison
            } else {
                let comparison = lhs.seatingCapacity < rhs.seatingCapacity
                return isAscending ? comparison : !comparison
            }
        }

        return sorted
    }
}

#Preview {
    NavigationStack {
        AircraftListView()
    }
}
