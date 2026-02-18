import SwiftData
import SwiftUI

struct AircraftListView: View {

    @Query var aircrafts: [Aircraft]

    @State private var selectedSort: AircraftSort = .registration
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var searchText: String = ""
    @State private var showAircraftRegistration: Bool = false

    var body: some View {
        VStack {
            Group {
                if displayedAircrafts.isEmpty {
                    fallbackBackground
                } else {
                    List {
                        ForEach(displayedAircrafts, id: \.id) { aircraft in
                            NavigationLink(destination: AircraftDetailView(aircraft: aircraft)) {
                                ListRow(aircraft: aircraft)
                            }
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
                prompt: "Search by registration or type"
            )
            .searchToolbarBehavior(.minimize)
            .sheet(isPresented: $showAircraftRegistration) {
                NavigationStack {
                    AircraftRegistrationContent(isPresented: $showAircraftRegistration)
                }
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
                                selectedSortOrder = selectedSortOrder == .ascending ? .descending : .ascending
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
                                    Image(systemName: selectedSortOrder == .ascending ? "arrow.up" : "arrow.down")
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
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "airplane")
                .resizable()
                .opacity(0.15)
                .frame(maxWidth: 150, maxHeight: 100)
            Text("No Aircraft Data Available.")
                .opacity(0.25)
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
                let comparison = lhs.registrationNumber.lowercased() < rhs.registrationNumber.lowercased()
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
