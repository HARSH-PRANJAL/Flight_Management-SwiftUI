import SwiftData
import SwiftUI

struct AirportRegistrationContent: View {
    @State var viewModel: AirportRegistrationFormViewModel
    @State private var showConfirmCloseAlert = false

    @Binding var isPresented: Bool
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(NotificationManager.self) var notificationManager

    @FocusState private var focusedField: FormFocus?

    var body: some View {
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

                registerButton
                disclaimerText
            }
            .navigationTitle("Airport Registration")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(hasChanges)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    if hasChanges {
                        showConfirmCloseAlert = true
                    } else {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showConfirmCloseAlert) {
            Button("Discard", role: .destructive) {
                isPresented = false
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }

    private var codeFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Airport Code",
                placeholder: "e.g., JFK, LHR",
                focus: .code,
                hasError: viewModel.fieldErrors[.code] != nil,
                text: $viewModel.code,
                focusedField: $focusedField
            )
            .autocorrectionDisabled(true)
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
                placeholder: "e.g., John F. Kennedy",
                focus: .name,
                hasError: viewModel.fieldErrors[.name] != nil,
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
                text: $viewModel.country,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.country) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .country)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.country])
        }
    }

    private var registerButton: some View {
        Button(action: handleRegistration) {
            Text("Register Airport")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
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

    private var hasChanges: Bool {
        return !viewModel.code.isEmpty ||
               !viewModel.name.isEmpty ||
               !viewModel.city.isEmpty ||
               !viewModel.country.isEmpty
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
