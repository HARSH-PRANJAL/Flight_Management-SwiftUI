import SwiftData
import SwiftUI

struct StaffListView: View {

    @Query var staffs: [Staff]

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
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                Picker("Availability", selection: $selectedFilter) {
                    Text("All").tag(StaffAvailabilityStatus?(nil))
                    ForEach(StaffAvailabilityStatus.allCases, id: \.self) {
                        status in
                        Text(status.rawValue).tag(Optional(status))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 8)
            }
            .navigationTitle("Staff List")
            .toolbar {
                toolbarFilterSortItem
            }
            .searchable(
                text: $searchText,
                prompt: "Search by staff"
            )
            .searchToolbarBehavior(.minimize)
        }
    }
}

// MARK: Toolbar Item
extension StaffListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
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
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "person.3")
                .resizable()
                .opacity(0.15)
                .frame(maxWidth: 150, maxHeight: 100)
            Text("No Staff Data Available.")
                .opacity(0.25)
        }
    }

    var displayedStaffs: [Staff] {
        var filtered = staffs.filter { staff in
            if selectedFilter == nil {
                return true
            } else {
                return staff.currentStatus == selectedFilter
            }

        }

        filtered = filtered.filter { staff in
            if searchText.isEmpty { return true }

            let nameMatch = staff.name
                .localizedCaseInsensitiveContains(searchText)

            let flightMatch =
                staff.currentTrip?
                .flightNumber
                .localizedCaseInsensitiveContains(searchText) ?? false

            return nameMatch || flightMatch
        }

        let sorted = filtered.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .name {
                let comparison = lhs.name.lowercased() < rhs.name.lowercased()
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
