import PhotosUI
import SwiftData
import SwiftUI

struct StaffRegistrationContent: View {
    @State var viewModel: StaffRegistrationFormViewModel

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(NotificationManager.self) var notificationManager

    @FocusState private var focusedField: FormFocus?
    @State private var showConfirmCloseAlert = false
    @State private var currentDetent: PresentationDetent = .large

    var isPresented: Binding<Bool>?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfilePhotoField(
                    selectedPhoto: $viewModel.selectedPhoto,
                    profilePreview: $viewModel.profilePreview,
                    onChangeAction: { item in
                        await viewModel.processPhoto(item)
                    }
                )

                VStack(spacing: 20) {
                    nameFieldSection
                    emailFieldSection
                    genderFieldSection
                    designationFieldSection
                    dateOfBirthFieldSection
                }
                .padding(.horizontal, 16)

                if !viewModel.isEditMode {
                    disclaimerText
                }
            }
        }
        .presentationDetents([.large, .height(650)], selection: $currentDetent)
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
                    isPresented?.wrappedValue = false
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    if viewModel.isDirty {
                        showConfirmCloseAlert = true
                    } else {
                        if let binding = isPresented {
                            binding.wrappedValue = false
                        } else {
                            dismiss()
                        }
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
                    viewModel.isDirty ? Color(.systemBlue) : Color(.systemGray3)
                )
            }
        }
        .alert("Discard Changes?", isPresented: $showConfirmCloseAlert) {
            Button("Discard", role: .destructive) {
                if let binding = isPresented {
                    binding.wrappedValue = false
                } else {
                    dismiss()
                }
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text(
                "You have unsaved changes. Are you sure you want to discard them?"
            )
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
                allowedCharacter: {
                    $0.isLetter || $0.isWhitespace
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

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Email",
                placeholder: "example@example.com",
                focus: .email,
                hasError: viewModel.fieldErrors[.email] != nil,
                maxLength: 255,
                allowedCharacter: {
                    $0.isASCII
                },
                text: $viewModel.email,
                focusedField: $focusedField
            )
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
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
                hasError: viewModel.fieldErrors[.date] != nil,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.day) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .date)
            }
            .onChange(of: viewModel.month) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .date)
            }
            .onChange(of: viewModel.year) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .date)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.date])
        }
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
    
    private var isFormValid: Bool {
        !viewModel.name.isEmpty &&
        !viewModel.email.isEmpty &&
        viewModel.gender != nil &&
        viewModel.role != nil &&
        !viewModel.day.isEmpty &&
        !viewModel.month.isEmpty &&
        !viewModel.year.isEmpty
    }

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
        if viewModel.isEditMode {
            guard let staffToEdit = viewModel.staffToEdit else { return }

            staffToEdit.name = viewModel.name
            if let photoData = viewModel.photoData {
                staffToEdit.profileImage = photoData
            }
            staffToEdit.profileBgColor = viewModel.profileBgColor

            do {
                try context.save()
                notificationManager.showSuccess(
                    "Staff profile updated successfully"
                )

                if let isPresented = isPresented {
                    isPresented.wrappedValue = false
                } else {
                    dismiss()
                }
            } catch {
                notificationManager.showError(
                    "Failed to update staff profile. Please try again."
                )
            }
        } else {
            let newStaff = Staff(
                name: viewModel.name,
                designation: viewModel.role!,
                gender: viewModel.gender!,
                email: viewModel.email,
                profileImage: viewModel.photoData,
                profileBgColor: viewModel.profileBgColor,
                dob: Calendar.current.date(
                    from: viewModel.dateOfBirthComponents
                )!
            )

            do {
                context.insert(newStaff)
                try context.save()
                notificationManager.showSuccess("Staff added successfully")

                dismiss()
            } catch {
                notificationManager.showError(
                    "Failed to add staff. Please try again."
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = StaffRegistrationFormViewModel()
    return StaffRegistrationContent(viewModel: viewModel)
        .modelContainer(for: Staff.self, inMemory: true)
}
