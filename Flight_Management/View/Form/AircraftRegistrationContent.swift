import SwiftData
import SwiftUI

struct AircraftRegistrationContent: View {
    @State var viewModel: AircraftRegistrationFormViewModel

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    registrationNumberFieldSection
                    typeFieldSection
                    seatingCapacityFieldSection
                    minimumStaffSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)

                registerButton
                disclaimerText
            }
            .navigationTitle("Aircraft Registration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var registrationNumberFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Registration Number",
                placeholder: "e.g., N12345",
                focus: .registrationNumber,
                hasError: viewModel.fieldErrors[.registrationNumber] != nil,
                text: $viewModel.registrationNumber,
                focusedField: $focusedField
            )
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.characters)
            .onChange(of: viewModel.registrationNumber) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .registrationNumber)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.registrationNumber])
        }
    }

    private var typeFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Aircraft Type",
                placeholder: "e.g., Boeing 737",
                focus: .type,
                hasError: viewModel.fieldErrors[.type] != nil,
                text: $viewModel.type,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.type) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .type)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.type])
        }
    }

    private var seatingCapacityFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Seating Capacity",
                placeholder: "e.g., 180",
                focus: .seatingCapacity,
                hasError: viewModel.fieldErrors[.seatingCapacity] != nil,
                text: $viewModel.seatingCapacity,
                focusedField: $focusedField
            )
            .keyboardType(.numberPad)
            .onChange(of: viewModel.seatingCapacity) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .seatingCapacity)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.seatingCapacity])
        }
    }

    private var minimumStaffSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minimum Staff Required")
                .formFieldLabel()

            ForEach(StaffRole.allCases, id: \.self) { role in
                HStack {
                    Text(role.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(Color(.label))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField(
                        "0",
                        text: Binding(
                            get: { viewModel.minimumStaffRequired[role] ?? "" },
                            set: { viewModel.minimumStaffRequired[role] = $0 }
                        )
                    )
                    .font(.system(size: 17))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .padding()
                    .frame(width: 80)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    }
                    .onChange(of: viewModel.minimumStaffRequired[role] ?? "") {
                        _,
                        _ in
                        viewModel.fieldErrors.removeValue(
                            forKey: .minimumStaffRequired
                        )
                    }
                }
            }

            if let error = viewModel.fieldErrors[.minimumStaffRequired] {
                FormErrorMessage(error: error)
            }
        }
    }

    private var registerButton: some View {
        Button(action: handleRegistration) {
            Text("Register Aircraft")
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
            "Aircraft will be added to the system and available for trip assignment."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 30)
    }

    private func handleRegistration() {
        if viewModel.saveAircraft(to: context) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AircraftRegistrationContent(
            viewModel: AircraftRegistrationFormViewModel()
        )
        .modelContainer(for: Aircraft.self, inMemory: true)
    }
}
