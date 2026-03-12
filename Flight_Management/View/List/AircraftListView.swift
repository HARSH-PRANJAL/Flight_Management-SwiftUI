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

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                fallbackBackground
            } else {
                List {
                    ForEach(viewModel.items, id: \.id) { aircraft in
                        NavigationLink(
                            destination: AircraftDetailView(aircraft: aircraft)
                        ) {
                            ListRow(aircraft: aircraft)
                        }
                        .onAppear {
                            if aircraft.id == viewModel.items.last?.id {
                                Task {
                                    await viewModel.loadMore(
                                        context: context,
                                        statusFilter: selectedStatus,
                                        searchText: searchText,
                                        sort: selectedSort,
                                        sortOrder: selectedSortOrder
                                    )
                                }
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadInitial(
                        context: context,
                        statusFilter: selectedStatus,
                        searchText: "",
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
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
                searchText: searchText,
                sort: selectedSort,
                sortOrder: selectedSortOrder
            )
        }
        .onChange(of: searchText) { _, newSearch in
            Task {
                await viewModel.loadInitial(
                    context: context,
                    statusFilter: selectedStatus,
                    searchText: newSearch,
                    sort: selectedSort,
                    sortOrder: selectedSortOrder
                )
            }
        }
        .onChange(of: selectedSort) { _, _ in
            Task {
                await viewModel.loadInitial(
                    context: context,
                    statusFilter: selectedStatus,
                    searchText: searchText,
                    sort: selectedSort,
                    sortOrder: selectedSortOrder
                )
            }
        }
        .onChange(of: selectedSortOrder) { _, _ in
            Task {
                await viewModel.loadInitial(
                    context: context,
                    statusFilter: selectedStatus,
                    searchText: searchText,
                    sort: selectedSort,
                    sortOrder: selectedSortOrder
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
                                searchText: searchText,
                                sort: selectedSort,
                                sortOrder: selectedSortOrder
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
                                searchText: searchText,
                                sort: selectedSort,
                                sortOrder: selectedSortOrder
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
                                searchText: searchText,
                                sort: selectedSort,
                                sortOrder: selectedSortOrder
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
                                selectedSortOrder =
                                    selectedSortOrder == .ascending
                                    ? .descending : .ascending
                            } else {
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
extension AircraftListView {
    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Aircraft", systemImage: "airplane")
        } description: {
            Text("Add aircraft to get started.")
        }
    }
}

#Preview {
    NavigationStack {
        AircraftListView()
    }
}
