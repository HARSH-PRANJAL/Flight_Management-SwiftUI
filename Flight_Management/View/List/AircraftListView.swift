import SwiftData
import SwiftUI

struct AircraftListView: View {

    @Query var aircrafts: [Aircraft]

    @State private var selectedSort: AircraftSort = .registration
    @State private var searchText: String = ""

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
            .toolbar {
                toolbarFilterSortItem
            }
            .searchable(
                text: $searchText,
                prompt: "Search by registration or type"
            )
            .searchToolbarBehavior(.minimize)
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
        var filtered = aircrafts.filter { aircraft in
            if searchText.isEmpty { return true }

            let registrationMatch = aircraft.registrationNumber
                .localizedCaseInsensitiveContains(searchText)
            let typeMatch = aircraft.type
                .localizedCaseInsensitiveContains(searchText)

            return registrationMatch || typeMatch
        }

        return filtered.sorted { lhs, rhs in
            if selectedSort == .registration {
                return lhs.registrationNumber.lowercased() < rhs.registrationNumber.lowercased()
            } else {
                return lhs.type.lowercased() < rhs.type.lowercased()
            }
        }
    }
}

// MARK: Sorting Enum
enum AircraftSort: String, CaseIterable {
    case registration = "Registration Number"
    case type = "Aircraft Type"
}

#Preview {
    NavigationStack {
        AircraftListView()
    }
}
