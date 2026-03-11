import SwiftData
import SwiftUI

struct AirportSearchDropdown: View {
    @Environment(\.modelContext) var context
    var allAirports: [Airport] {
        let code = self.searchText.uppercased()
        let searchText = self.searchText.capitalized
        let predicate = #Predicate<Airport> {
            $0.name.contains(searchText) || $0.city.contains(searchText)
                || $0.code.contains(code)
        }

        let descriptor = FetchDescriptor<Airport>(predicate: predicate)
        let result = try? context.fetch(descriptor)

        return result ?? []
    }

    let onAirportSelected: (Airport) -> Void
    let excludeAirports: [Airport]

    @State private var searchText: String = ""
    @State private var isExpanded: Bool = false
    @FocusState private var isFocused: Bool

    var filteredAirports: [Airport] {
        let excluded = Set(excludeAirports.map { $0.code })
        let filtered = allAirports.filter { !excluded.contains($0.code) }

        if searchText.isEmpty {
            return []
        }

        return filtered.sorted { $0.code < $1.code }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.systemGray))

                TextField("Search by code, name or city", text: $searchText)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        if newValue {
                            isExpanded = true
                        }
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.systemGray3))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill).opacity(0.5))
                    .stroke(Color(.systemGray3).opacity(0.5), lineWidth: 1)
            )

            // Dropdown List
            if isExpanded && !filteredAirports.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredAirports, id: \.id) { airport in
                            Button(action: {
                                onAirportSelected(airport)
                                searchText = ""
                                isExpanded = false
                                isFocused = false
                            }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(airport.code)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundColor(Color(.label))

                                        Text(airport.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(.systemGray))
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    Text(airport.locationLabel)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.systemGray2))
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }

                            if airport.id != filteredAirports.last?.id {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 8)
                }
                .frame(maxHeight: 300)
                .scrollIndicators(.automatic)
            }

            // No results
            if isExpanded && filteredAirports.isEmpty && !searchText.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.badge.airplane")
                        .font(.system(size: 24))
                        .foregroundColor(Color(.systemGray3))

                    Text("No airports found")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 8)
            }
        }
        .onChange(of: isFocused) { _, newValue in
            if !newValue && searchText.isEmpty {
                isExpanded = false
            }
        }
    }
}

#Preview {
    @Previewable @State var excludedAirports: [Airport] = []

    VStack(spacing: 20) {
        AirportSearchDropdown(
            onAirportSelected: { airport in
                print("Selected: \(airport.code)")
            },
            excludeAirports: excludedAirports
        )

        Spacer()
    }
    .padding()
    .modelContainer(for: Airport.self, inMemory: true)
}
