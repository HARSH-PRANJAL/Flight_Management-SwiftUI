import SwiftData
import SwiftUI

struct AirportRegistrationContent: View {
    @State var viewModel: AirportRegistrationFormViewModel =
        AirportRegistrationFormViewModel()
    @State private var showConfirmCloseAlert = false
    @State private var currentDetent: PresentationDetent = .large

    @Binding var isPresented: Bool
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(NotificationManager.self) var notificationManager

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea(.all)
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        codeFieldSection
                        nameFieldSection
                        cityFieldSection
                        countryFieldSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)

                    Spacer()
                    disclaimerText
                }
                .navigationTitle("Add Airport")
                .navigationBarTitleDisplayMode(.inline)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
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
            .onAppear {
                viewModel.originalSnapshot = viewModel.currentSnapshot()
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
            .alert("Discard Changes?", isPresented: $showConfirmCloseAlert) {
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

    private var codeFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Airport Code",
                placeholder: "e.g., JFK, LHR",
                focus: .code,
                hasError: viewModel.fieldErrors[.name] != nil,
                maxLength: 5,
                allowedCharacter: {
                    $0.isLetter
                },
                text: $viewModel.code,
                focusedField: $focusedField
            )
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.characters)
            .onChange(of: viewModel.code) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .name)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.name])
        }
    }

    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Airport Name",
                placeholder: "e.g., John F. Kennedy",
                focus: .name,
                hasError: viewModel.fieldErrors[.name] != nil,
                allowedCharacter: {
                    $0.isLetter || $0.isNumber || $0.isWhitespace
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
                allowedCharacter: {
                    $0.isLetter || $0.isWhitespace
                },
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
                placeholder: "e.g., USA",
                focus: .country,
                hasError: viewModel.fieldErrors[.country] != nil,
                allowedCharacter: {
                    $0.isLetter || $0.isWhitespace
                },
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
            "Airport will be added to the system and available for route configuration."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 30)
    }

    private var isFormValid: Bool {
        !viewModel.code.isEmpty && !viewModel.name.isEmpty
            && !viewModel.city.isEmpty && !viewModel.country.isEmpty
    }

    private func handleRegistration() {
        if viewModel.saveAirport(to: context) {
            notificationManager.showSuccess("Airport registered successfully")
            dismiss()
        } else {
            notificationManager.showError(
                "Failed to register airport. Please try again."
            )
        }
    }
}

#Preview {
    NavigationStack {
        AirportRegistrationContent(
            viewModel: AirportRegistrationFormViewModel(),
            isPresented: .constant(false)
        )
        .modelContainer(for: Airport.self, inMemory: true)
    }
}
