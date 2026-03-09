import SwiftUI

struct AircraftSelectorView: View {

    let allAircraft: [Aircraft]
    @Binding var selectedAircraft: Aircraft?

    @Environment(\.dismiss) private var dismiss

    @State private var localSelection: Aircraft?
    @State private var searchText = ""
    @State private var currentDetent: PresentationDetent = .large
    @State private var showDiscardAlert = false

    init(
        allAircraft: [Aircraft],
        selectedAircraft: Binding<Aircraft?>
    ) {
        self.allAircraft = allAircraft
        self._selectedAircraft = selectedAircraft
        self._localSelection = State(
            initialValue: selectedAircraft.wrappedValue
        )
    }

    var body: some View {
        NavigationStack {
            List {

                if let selected = localSelection {
                    Section("Selected") {
                        aircraftRow(aircraft: selected)
                    }
                }

                Section("Available") {
                    ForEach(unselectedItems, id: \.id) { aircraft in
                        aircraftRow(aircraft: aircraft)
                    }

                    if unselectedItems.isEmpty {
                        fallbackBackground
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(
                text: $searchText,
                prompt: "Search by registration or type"
            )
            .navigationTitle("Select Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                closeButton
                saveButton
            }
        }
        .presentationDetents(
            [.large, .height(650)],
            selection: $currentDetent
        )
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(isDirty)
        .onChange(of: currentDetent) { oldValue, newValue in
            guard newValue != oldValue else { return }

            if newValue == .height(650) {
                if isDirty {
                    showDiscardAlert = true
                    currentDetent = .large
                } else {
                    dismiss()
                }
            }
        }
        .alert(
            "Discard Changes?",
            isPresented: $showDiscardAlert
        ) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes.")
        }
    }
}

// MARK: - UI
extension AircraftSelectorView {

    var closeButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                if isDirty {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
            }
        }
    }

    var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
                selectedAircraft = localSelection
                dismiss()
            } label: {
                Image(systemName: "checkmark")
            }
            .disabled(!isDirty)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                isDirty ? Color(.systemBlue) : Color(.systemGray3)
            )
        }
    }

    @ViewBuilder
    private func aircraftRow(aircraft: Aircraft) -> some View {

        let isSelected = localSelection?.id == aircraft.id

        Button {
            localSelection = isSelected ? nil : aircraft
        } label: {
            ListRow(selectedAircraft: aircraft)
        }
    }

    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Aircraft", systemImage: "airplane")
        } description: {
            Text("All aircraft have been assigned.")
        }
    }
}

// MARK: Util
extension AircraftSelectorView {

    private var isDirty: Bool {
        localSelection?.id != selectedAircraft?.id
    }

    private var filteredAircraft: [Aircraft] {
        if searchText.isEmpty { return allAircraft }
        let filtered = allAircraft.filter {
            $0.registrationNumber
                .localizedCaseInsensitiveContains(searchText)
                || ($0.type.localizedCaseInsensitiveContains(searchText))
        }

        return filtered.sorted {
            $0.trips.count <= $1.trips.count
                || $0.seatingCapacity < $1.seatingCapacity
        }
    }

    private var unselectedItems: [Aircraft] {
        filteredAircraft.filter { $0.id != localSelection?.id }
    }
}
