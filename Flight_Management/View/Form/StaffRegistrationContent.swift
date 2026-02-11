import SwiftData
import SwiftUI

struct StaffRegistrationContent: View {
    @State var viewModel: StaffRegistrationFormViewModel

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfilePhotoField(viewModel: viewModel)

                VStack(spacing: 20) {
                    nameFieldSection
                    emailFieldSection
                    genderFieldSection
                    designationFieldSection
                    dateOfBirthFieldSection
                }
                .padding(.horizontal, 16)

                registerButton

                disclaimerText
            }
            .navigationTitle("Staff Registration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Form Field Sections
    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Name",
                placeholder: "Enter your full name",
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

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Email",
                placeholder: "example@example.com",
                focus: .email,
                hasError: viewModel.fieldErrors[.email] != nil,
                text: $viewModel.email,
                focusedField: $focusedField
            )
            .autocorrectionDisabled(true)
            .keyboardType(.emailAddress)
            .onChange(of: viewModel.email) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .email)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.email])
        }
    }

    private var genderFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormPickerField<Gender>(
                label: "Gender",
                placeholder: "Select gender",
                focus: .gender,
                hasError: viewModel.fieldErrors[.gender] != nil,
                selection: $viewModel.gender,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.gender) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .gender)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.gender])
        }
    }

    private var designationFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormPickerField<StaffRole>(
                label: "Designation",
                placeholder: "Select designation",
                focus: .role,
                hasError: viewModel.fieldErrors[.role] != nil,
                selection: $viewModel.role,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.role) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .role)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.role])
        }
    }

    private var dateOfBirthFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormDateField(
                viewModel: viewModel,
                hasError: viewModel.fieldErrors[.dateOfBirth] != nil,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.day) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .dateOfBirth)
            }
            .onChange(of: viewModel.month) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .dateOfBirth)
            }
            .onChange(of: viewModel.year) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .dateOfBirth)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.dateOfBirth])
        }
    }

    private var registerButton: some View {
        Button(action: handleRegistration) {
            Text("Register")
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
            "Your information will be used for staff identification and internal records only."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.top, 16)
    }

    // MARK: - Reegister
    private func handleRegistration() {
        viewModel.fieldErrors.removeAll()
        var isValid = true

        if !viewModel.validateName() {
            isValid = false
        }
        if !viewModel.validateEmail() {
            isValid = false
        }
        if !viewModel.validateGender() {
            isValid = false
        }
        if !viewModel.validateDesignation() {
            isValid = false
        }
        if !viewModel.validateDateOfBirth() {
            isValid = false
        }

        if !isValid { return }

        submitRegistration()
    }

    private func submitRegistration() {
        let newStaff = Staff(
            name: viewModel.name,
            designation: viewModel.role!,
            gender: viewModel.gender!,
            email: viewModel.email,
            profileImage: viewModel.photoData,
            dob: Calendar.current.date(from: viewModel.dateOfBirthComponents)!
        )

        do {
            context.insert(newStaff)
            try context.save()
            viewModel.submissionState = .success
            print("Staff saved\n \(newStaff.id)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                viewModel.resetForm()
                viewModel.submissionState = .none
                dismiss()
            }
        } catch {
            viewModel.submissionState = .error
        }
    }
}

#Preview {
    @Previewable @State var viewModel = StaffRegistrationFormViewModel()
    return StaffRegistrationContent(viewModel: viewModel)
        .modelContainer(for: Staff.self, inMemory: true)
}
