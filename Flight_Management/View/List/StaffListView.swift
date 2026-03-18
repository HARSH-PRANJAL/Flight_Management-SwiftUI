import SwiftData
import SwiftUI

struct StaffListView: View {

    @Environment(\.modelContext) private var context
    @Environment(SessionManager.self) private var session

    @State private var viewModel = StaffListViewModel()

    @State private var selectedFilter: StaffAvailabilityStatus? = nil
    @State private var selectedSort: StaffSort = .name
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""
    @State private var isAddStaffPresented: Bool = false

    var externalStaffs: [Staff] = []
    var navigationTitle: String = "Staff List"
    var requiredFilters: [StaffAvailabilityStatus] = StaffAvailabilityStatus
        .allCases
    /// Optional selection binding for split-view layouts.
    /// When provided, rows update the selection instead of pushing a detail view.
    var selection: Binding<Staff?>? = nil

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if displayedStaffs.isEmpty {
                    fallbackBackground
                } else {
                    Group {
                        if externalStaffs.isEmpty {
                            list
                                .refreshable {
                                    await viewModel.loadInitial(
                                        context: context,
                                        filter: selectedFilter,
                                        searchText: searchText,
                                        sort: selectedSort,
                                        sortOrder: selectedSortOrder
                                    )
                                    await loadUntilVisible()
                                }
                        } else {
                            list
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                toolbarFilterSortItem
                if let user = session.user,
                    user.role == UserRole.admin.rawValue
                {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isAddStaffPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                prompt: "Search by name"
            )
            .searchToolbarBehavior(.minimize)
            .task {
                guard externalStaffs.isEmpty else { return }
                await viewModel.loadInitial(
                    context: context,
                    filter: selectedFilter,
                    searchText: searchText,
                    sort: selectedSort,
                    sortOrder: selectedSortOrder
                )
                await loadUntilVisible()
            }
            .onChange(of: selectedFilter) { _, newFilter in
                guard externalStaffs.isEmpty else { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: newFilter,
                        searchText: searchText,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                    await loadUntilVisible()
                }
            }
            .onChange(of: searchText) { _, newSearch in
                guard externalStaffs.isEmpty else { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: newSearch,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                    await loadUntilVisible()
                }
            }
            .onChange(of: selectedSort) { _, _ in
                guard externalStaffs.isEmpty else { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: searchText,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                    await loadUntilVisible()
                }
            }
            .onChange(of: selectedSortOrder) { _, _ in
                guard externalStaffs.isEmpty else { return }
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        filter: selectedFilter,
                        searchText: searchText,
                        sort: selectedSort,
                        sortOrder: selectedSortOrder
                    )
                    await loadUntilVisible()
                }
            }
        }
        .sheet(isPresented: $isAddStaffPresented) {
            NavigationStack {
                StaffRegistrationForm()
                    .navigationTitle("Add Staff")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    var list: some View {
        List {
            ForEach(displayedStaffs, id: \.id) { staff in
                Group {
                    if let selection {
                        Button {
                            selection.wrappedValue = staff
                        } label: {
                            ListRow(staff: staff)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            selection.wrappedValue?.id == staff.id
                                ? Color(.systemBlue).opacity(0.15)
                            : Color(.systemBackground)
                        )
                    } else {
                        NavigationLink(
                            destination: StaffDetailView(staff: staff)
                        ) {
                            ListRow(staff: staff)
                        }
                    }
                }
                .onAppear {
                    guard externalStaffs.isEmpty else { return }
                    if staff.id == displayedStaffs.last?.id {
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

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .listStyle(.insetGrouped)
    }
}

// MARK: Toolbar Item
extension StaffListView {

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

    private func loadUntilVisible() async {
        while displayedStaffs.isEmpty && viewModel.hasMore
            && !viewModel.isLoading
        {
            await viewModel.loadMore(
                context: context,
                filter: selectedFilter,
                searchText: searchText,
                sort: selectedSort,
                sortOrder: selectedSortOrder
            )
        }
    }

    var displayedStaffs: [Staff] {
        guard externalStaffs.isEmpty else {
            return externalStaffs.sorted { lhs, rhs in
                let asc = selectedSortOrder == .ascending
                if selectedSort == .name {
                    let cmp =
                        lhs.name.localizedStandardCompare(rhs.name)
                        == .orderedAscending
                    return asc ? cmp : !cmp
                } else {
                    return asc
                        ? lhs.totalTripHours < rhs.totalTripHours
                        : lhs.totalTripHours > rhs.totalTripHours
                }
            }
        }
        return viewModel.items
    }
}

#Preview {
    NavigationStack {
        StaffListView()
    }
}
