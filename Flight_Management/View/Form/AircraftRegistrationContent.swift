import SwiftData
import SwiftUI

struct AircraftRegistrationContent: View {
    var aircraft: Aircraft? = nil
    @State var viewModel: AircraftRegistrationFormViewModel
    @State private var showConfirmCloseAlert = false
    @State private var currentDetent: PresentationDetent = .large

    @Binding var isPresented: Bool
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(NotificationManager.self) var notificationManager

    @FocusState private var focusedField: FormFocus?
    @FocusState private var isStaffInputFocused: Bool

    init(aircraft: Aircraft? = nil, isPresented: Binding<Bool>) {
        self.aircraft = aircraft
        self._isPresented = isPresented
        if let aircraft = aircraft {
            _viewModel = State(
                initialValue: AircraftRegistrationFormViewModel(
                    aircraft: aircraft
                )
            )
        } else {
            _viewModel = State(
                initialValue: AircraftRegistrationFormViewModel()
            )
        }
    }

    private var focusScrollMap: [FormFocus: String] {
        [
            .registrationNumber: "type",
            .type: "seating",
            .seatingCapacity: "staff",
        ]
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea(.all)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            registrationNumberFieldSection
                                .id("regNum")
                            typeFieldSection
                                .id("type")
                            seatingCapacityFieldSection
                                .id("seating")
                            minimumStaffSection
                                .id("staff")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)

                        Spacer()
                        if aircraft == nil {
                            disclaimerText
                        }
                    }
                    .navigationTitle(
                        aircraft != nil ? "Update Aircraft" : "Add Aircraft"
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: focusedField) { _, newFocus in
                    guard let focus = newFocus,
                        let targetID = focusScrollMap[focus]
                    else { return }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(targetID, anchor: .bottom)
                    }
                }
                .onAppear {
                    focusedField = .registrationNumber
                    viewModel.originalSnapshot = viewModel.currentSnapshot()
                }
                .onTapGesture {
                    isStaffInputFocused = false
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
            }  // ScrollViewReader
        }
    }
}

// MARK: UI
extension AircraftRegistrationContent {

    private var registrationNumberFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Registration Number",
                placeholder: "e.g., N12345",
                focus: .registrationNumber,
                hasError: viewModel.fieldErrors[.registrationNumber] != nil,
                maxLength: 8,
                allowedCharacter: {
                    $0.isLetter || $0.isNumber || $0 == "-"
                },
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
                maxLength: 50,
                allowedCharacter: {
                    $0.isLetter || $0.isNumber || $0.isWhitespace
                },
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
                allowedCharacter: {
                    $0.isNumber
                },
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
                    .focused($isStaffInputFocused)
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

    private var isFormValid: Bool {
        !viewModel.registrationNumber.isEmpty && !viewModel.type.isEmpty
            && !viewModel.seatingCapacity.isEmpty
    }
}

// MARK: Util
extension AircraftRegistrationContent {
    private func handleRegistration() {

        guard viewModel.validateAll() else { return }

        if let aircraft = aircraft {
            // Update mode
            if viewModel.updateAircraft(aircraft, in: context) {
                notificationManager.showSuccess("Aircraft updated successfully")
                isPresented = false
            } else {
                notificationManager.showError(
                    "Failed to update aircraft. Please try again."
                )
            }
        } else {
            // Create mode
            if viewModel.saveAircraft(to: context) {
                notificationManager.showSuccess(
                    "Aircraft registered successfully"
                )
                isPresented = false
            } else {
                notificationManager.showError(
                    "Failed to register aircraft. Please try again."
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        AircraftRegistrationContent(
            isPresented: .constant(false)
        )
        .modelContainer(for: Aircraft.self, inMemory: true)
    }
}
