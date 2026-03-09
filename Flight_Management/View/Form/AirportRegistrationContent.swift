import SwiftData
import SwiftUI

struct AirportRegistrationContent: View {
    var airport: Airport? = nil

    @State var viewModel: AirportRegistrationFormViewModel =
        AirportRegistrationFormViewModel()
    @State private var showConfirmCloseAlert = false
    @State private var currentDetent: PresentationDetent = .large

    @Binding var isPresented: Bool
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(NotificationManager.self) var notificationManager

    @FocusState private var focusedField: FormFocus?

    private var focusScrollMap: [FormFocus: String] {
        [
            .code: "field_name",
            .name: "field_city",
            .city: "field_country",
            .country: "field_disclaimer",
        ]
    }
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea(.all)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        codeFieldSection
                            .id("field_code")
                        nameFieldSection
                            .id("field_name")
                        cityFieldSection
                            .id("field_city")
                        countryFieldSection
                            .id("field_country")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)

                    Spacer(minLength: 20)
                    disclaimerText
                        .id("field_disclaimer")
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle(
                    viewModel.isEditMode ? "Edit Airport" : "Add Airport"
                )
                .navigationBarTitleDisplayMode(.inline)
                .onChange(of: focusedField) { _, newFocus in
                    guard let focus = newFocus,
                        let targetID = focusScrollMap[focus]
                    else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(targetID, anchor: .bottom)
                    }
                }
                .onAppear {
                    if let airport {
                        viewModel = AirportRegistrationFormViewModel(
                            airport: airport
                        )
                    }
                    viewModel.originalSnapshot = viewModel.currentSnapshot()
                    focusedField = viewModel.isEditMode ? .name : .code
                }
                .presentationDetents(
                    [.large, .height(650)],
                    selection: $currentDetent
                )
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(viewModel.isDirty)
                .onChange(of: currentDetent) { oldValue, newValue in
                    guard newValue != oldValue else { return }
                    if newValue == .height(650) {
                        if viewModel.isDirty {
                            showConfirmCloseAlert = true
                            withAnimation(
                                .spring(response: 0.38, dampingFraction: 0.85)
                            ) {
                                currentDetent = .large
                            }
                        } else {
                            isPresented = false
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            if viewModel.isDirty {
                                showConfirmCloseAlert = true
                            } else {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            handleRegistration()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .disabled(!viewModel.isDirty)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            viewModel.isDirty
                                ? Color(.systemBlue) : Color(.systemGray3)
                        )
                    }
                }
                .alert("Discard Changes?", isPresented: $showConfirmCloseAlert)
                {
                    Button("Discard", role: .destructive) {
                        isPresented = false
                    }
                    Button("Keep Editing", role: .cancel) {}
                } message: {
                    Text(
                        "You have unsaved changes. Are you sure you want to discard them?"
                    )
                }
            }
        }
    }

}

//MARK: UI
extension AirportRegistrationContent {

    private var codeFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Airport Code",
                placeholder: "e.g., JFK, LHR",
                focus: .code,
                hasError: viewModel.fieldErrors[.code] != nil,
                maxLength: 5,
                allowedCharacter: { $0.isLetter },
                text: $viewModel.code,
                focusedField: $focusedField
            )
            .textInputAutocapitalization(.characters)
            .onChange(of: viewModel.code) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .code)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.code])
        }
    }

    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Airport Name",
                placeholder: "e.g., John F. Kennedy International",
                focus: .name,
                hasError: viewModel.fieldErrors[.name] != nil,
                allowedCharacter: {
                    $0.isLetter || $0.isNumber || $0.isWhitespace || $0 == "."
                        || $0 == "-"
                },
                text: $viewModel.name,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.name) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .name)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.name])
        }
    }

    private var cityFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "City",
                placeholder: "e.g., New York",
                focus: .city,
                hasError: viewModel.fieldErrors[.city] != nil,
                allowedCharacter: { $0.isLetter || $0.isWhitespace },
                text: $viewModel.city,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.city) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .city)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.city])
        }
    }

    private var countryFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Country",
                placeholder: "e.g., United States",
                focus: .country,
                hasError: viewModel.fieldErrors[.country] != nil,
                allowedCharacter: { $0.isLetter || $0.isWhitespace },
                text: $viewModel.country,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.country) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .country)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.country])
        }
    }

    private var disclaimerText: some View {
        Text(
            viewModel.isEditMode
                ? "Changes will be reflected across all routes that use this airport."
                : "Airport will be added to the system and available for route configuration."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 30)
    }
}

// MARK: - Util
extension AirportRegistrationContent {

    private func isUniqueCode() -> Bool {
        let code = viewModel.code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let editingID = airport?.id

        let descriptor = FetchDescriptor<Airport>(
            predicate: #Predicate {
                $0.code == code && (editingID == nil || $0.id != editingID!)
            }
        )

        do {
            return (try context.fetch(descriptor)).isEmpty
        } catch {
            return false
        }
    }

    private func handleRegistration() {
        guard viewModel.validateAll() else { return }

        if !isUniqueCode() {
            viewModel.fieldErrors[.code] =
                "This airport code is already in use."
            return
        }

        if let airport {
            if viewModel.updateAirport(airport, in: context) {
                notificationManager.showSuccess("Airport updated successfully")
                isPresented = false
            } else {
                notificationManager.showError(
                    "Failed to update airport. Please try again."
                )
            }
        } else {
            if viewModel.saveAirport(to: context) {
                notificationManager.showSuccess("Airport added successfully")
                isPresented = false
            } else {
                notificationManager.showError(
                    "Failed to add airport. Please try again."
                )
            }
        }
    }
}

#Preview("Add Mode") {
    NavigationStack {
        AirportRegistrationContent(isPresented: .constant(true))
            .modelContainer(for: Airport.self, inMemory: true)
            .environment(NotificationManager.shared)
    }
}
