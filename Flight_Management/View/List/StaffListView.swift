import SwiftData
import SwiftUI

struct StaffListView: View {

    @Environment(\.modelContext) private var context

    @State private var viewModel = StaffListViewModel()

    @State private var selectedFilter: StaffAvailabilityStatus? = nil
    @State private var selectedSort: StaffSort = .name
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if displayedStaffs.isEmpty {
                    fallbackBackground
                } else {
                    List {
                        ForEach(displayedStaffs, id: \.id) { staff in
                            NavigationLink(
                                destination: StaffDetailView(staff: staff)
                            ) {
                                ListRow(staff: staff)
                            }
                            .onAppear {
                                if staff.id == displayedStaffs.last?.id {
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
            .navigationTitle("Staff List")
            .toolbar {
                toolbarFilterSortItem
            }
            .searchable(
                text: $searchText,
                prompt: "Enter name, or current flight number"
            )
            .searchToolbarBehavior(.minimize)
            .task {
                await viewModel.loadInitial(
                    context: context,
                    filter: selectedFilter,
                    searchText: searchText
                )
            }
            .onChange(of: selectedFilter) { _, newFilter in
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: newFilter,
                        searchText: searchText
                    )
                }
            }
            .onChange(of: searchText) { _, newSearch in
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
extension StaffListView {

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
                            StaffAvailabilityStatus.allCases,
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
                    ForEach(StaffSort.allCases, id: \.self) { sort in
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
extension StaffListView {
    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Staff", systemImage: "person.2")
        } description: {
            Text("Add staff members to get started.")
        }
    }

    var displayedStaffs: [Staff] {
        let sorted = viewModel.items.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .name {
                let comparison = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                return isAscending ? comparison : !comparison
            } else {
                let comparison =
                    lhs.currentStatus.rawValue < rhs.currentStatus.rawValue
                return isAscending ? comparison : !comparison
            }
        }

        return sorted
    }
}

#Preview {
    NavigationStack {
        StaffListView()
    }
}
