import SwiftData
import SwiftUI

struct AircraftListView: View {

    @Query var aircrafts: [Aircraft]

    @State private var selectedSort: AircraftSort = .registration
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""
    @State private var showAircraftRegistration: Bool = false
    @State private var selectedAircraft: Aircraft?

    var body: some View {
        NavigationSplitView {
            Group {
                if displayedAircrafts.isEmpty {
                    fallbackBackground
                } else {
                    List(
                        displayedAircrafts,
                        id: \.id,
                        selection: $selectedAircraft
                    ) { aircraft in
                        ListRow(aircraft: aircraft)
                    }
                    .listStyle(.insetGrouped)
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
                prompt: "Search by registration or type"
            )
            .searchToolbarBehavior(.minimize)
            .sheet(isPresented: $showAircraftRegistration) {
                NavigationStack {
                    AircraftRegistrationContent(
                        isPresented: $showAircraftRegistration
                    )
                }
            }
        } detail: {
            if let aircraft = selectedAircraft {
                AircraftDetailView(aircraft: aircraft)
            } else {
                Text("Select an aircraft")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: Toolbar Item
extension AircraftListView {

    var toolbarFilterSortItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
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
        let filtered = aircrafts.filter { aircraft in
            if searchText.isEmpty { return true }

            let registrationMatch = aircraft.registrationNumber
                .localizedCaseInsensitiveContains(searchText)
            let typeMatch = aircraft.type
                .localizedCaseInsensitiveContains(searchText)

            return registrationMatch || typeMatch
        }

        return filtered.sorted { lhs, rhs in
            let isAscending = selectedSortOrder == .ascending

            if selectedSort == .registration {
                let comparison =
                    lhs.registrationNumber.lowercased()
                    < rhs.registrationNumber.lowercased()
                return isAscending ? comparison : !comparison
            } else {
                let comparison = lhs.seatingCapacity < rhs.seatingCapacity
                return isAscending ? comparison : !comparison
            }
        }
    }
}

// MARK: Sorting Enum
enum AircraftSort: String, CaseIterable {
    case registration = "Registration Number"
    case seatingCapacity = "Seating Capacity"
}

#Preview {
    NavigationStack {
        AircraftListView()
    }
}
