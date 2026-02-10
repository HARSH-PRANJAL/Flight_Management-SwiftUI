import SwiftData
import SwiftUI

struct StaffListView: View {

    @Query var staffs: [Staff]

    @State private var isRegistrationFormPresented: Bool = false
    @State private var selectedFilter: StaffAvailabilityStatus? = nil
    @State private var selectedSort: StaffSort = .name
    @State private var searchText: String = ""
    @State private var isSearchFocused: Bool = false

    var body: some View {
        VStack {
            Group {
                if displayedStaffs.isEmpty {
                    fallbackBackground
                } else {
                    List {
                        ForEach(displayedStaffs, id: \.id) { staff in
                            ListRow(staff: staff)
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearchFocused,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search by name or flight number"
            )
            .toolbar {
                toolbarFilterSortItem
            }
            .sheet(isPresented: $isRegistrationFormPresented) {
                StaffRegistrationForm()
            }
        }
    }
}

// MARK: Toolbar Item
extension StaffListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Section("Filter") {
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
                Divider()
                Section("Sort by") {
                    ForEach(StaffSort.allCases, id: \.self) { sort in
                        Button {
                            selectedSort = sort
                        } label: {
                            HStack {
                                Text(sort.rawValue)
                                if selectedSort == sort {
                                    Spacer()
                                    Image(systemName: "checkmark")
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
                .opacity(0.5)
                .frame(maxWidth: 150, maxHeight: 100)
            Text("No Staff Data Available.")
            Spacer()
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

        return filtered.sorted { lhs, rhs in
            if selectedSort == .name {
                return lhs.name.lowercased() < rhs.name.lowercased()
            } else {
                return lhs.currentStatus.rawValue < rhs.currentStatus.rawValue
            }
        }
    }
}

#Preview {
    NavigationStack {
        StaffListView()
    }
}
