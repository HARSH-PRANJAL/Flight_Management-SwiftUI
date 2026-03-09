import SwiftData
import SwiftUI

struct StaffSelectorView: View {
    let role: StaffRole
    let requiredCount: Int
    let allStaff: [Staff]

    @Binding var selectedStaff: [Staff]

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = StaffListViewModel()
    @State private var localSelection: [Staff]
    @State private var searchText = ""
    @State private var currentDetent: PresentationDetent = .large
    @State private var showDiscardAlert = false

    init(
        role: StaffRole,
        requiredCount: Int,
        allStaff: [Staff],
        selectedStaff: Binding<[Staff]>
    ) {
        self.role = role
        self.requiredCount = requiredCount
        self.allStaff = allStaff
        self._selectedStaff = selectedStaff
        self._localSelection = State(initialValue: selectedStaff.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            staffList
                .padding(.top, -10)
                .searchable(text: $searchText, prompt: "Search by name")
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    closeButton
                    saveButton
                }
        }
        .presentationDetents([.large, .height(650)], selection: $currentDetent)
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(isDirty)
        .onChange(of: currentDetent) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if newValue == .height(650) {
                if isDirty {
                    showDiscardAlert = true
                    withAnimation(
                        .spring(response: 0.38, dampingFraction: 0.85)
                    ) {
                        currentDetent = .large
                    }
                } else {
                    dismiss()
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text(
                "You have unsaved changes. Are you sure you want to discard them?"
            )
        }
    }
}

// MARK: - UI
extension StaffSelectorView {
    
    var closeButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
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
                selectedStaff = localSelection
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

    private var navigationTitle: String {
        let current = localSelection.count
        switch role {
        case .pilot: return "Pilots (\(current)/\(requiredCount))"
        case .coPilot: return "Co-Pilots (\(current)/\(requiredCount))"
        case .cabinCrew: return "Crew (\(current)/\(requiredCount))"
        }
    }
    
    var fallbackBackground: some View {
        ContentUnavailableView {
            Label("", systemImage: "person.2")
        } description: {
            Text("There is no available \(role.rawValue.lowercased()).")
        }
    }

    private var staffList: some View {
        List {
            if !localSelection.isEmpty {
                Section("Selected") {
                    ForEach(localSelection) { staff in
                        staffRow(staff: staff)
                    }
                }
            }

            Section("Available") {
                ForEach(unselectedItems, id: \.id) { staff in
                    staffRow(staff: staff)
                }

                if unselectedItems.isEmpty {
                    fallbackBackground
                }
            }
        }
    }

    @ViewBuilder
    private func staffRow(staff: Staff) -> some View {
        let isSelected = localSelectedIDs.contains(staff.id)
        let canSelectMore = !isSelected && localSelection.count < requiredCount

        Button {
            if isSelected {
                localSelection.removeAll { $0.id == staff.id }
            } else if canSelectMore {
                localSelection.append(staff)
            }
        } label: {
            ListRow(replacementStaff: staff)
                .opacity(!isSelected && !canSelectMore ? 0.4 : 1.0)
        }
        .disabled(!isSelected && !canSelectMore)
    }
}

// MARK: Util
extension StaffSelectorView {
    private var isDirty: Bool {
        Set(localSelection.map(\.id)) != Set(selectedStaff.map(\.id))
    }

    private var isComplete: Bool {
        localSelection.count == requiredCount
    }

    private var availableItems: [Staff] {
        allStaff.filter {
            var result = true
            if !searchText.isEmpty {
                result =
                    result
                    && $0.nameSearchKey.contains(
                        Staff.normalisedSearchKey(from: searchText)
                    )
            }
            return result
        }
    }

    private var localSelectedIDs: Set<UUID> {
        Set(localSelection.map(\.id))
    }

    private var unselectedItems: [Staff] {
        availableItems.filter { !localSelectedIDs.contains($0.id) }
    }
}
