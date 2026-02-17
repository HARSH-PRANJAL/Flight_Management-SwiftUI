import SwiftData
import SwiftUI

struct TripRegistrationContent: View {
    @State var viewModel: TripRegistrationFormViewModel

    var isPresented: Binding<Bool>?
    @State private var showConfirmCloseAlert = false

    @Environment(\.modelContext) var context
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.dismiss) var dismiss

    @Query var routes: [Route]
    @Query var aircrafts: [Aircraft]
    @Query var staffs: [Staff]

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                VStack(spacing: 12) {
                    tripNumber
                    datePicker
                        .disabled(viewModel.isEditMode)
                    routePicker
                    aircraftPicker
                        .disabled(viewModel.isEditMode)

                    if viewModel.selectedRoute != nil {
                        staffSelector
                            .disabled(viewModel.isEditMode)
                    }

                    if let err = viewModel.fieldErrors["staff"] {
                        Text(err).foregroundColor(.red).font(.caption)
                    }

                    registerButton
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(
                viewModel.isEditMode ? "Update Trip" : "Trip Registration"
            )
            .navigationBarTitleDisplayMode(.inline)
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    if hasChanges {
                        showConfirmCloseAlert = true
                    } else {
                        isPresented?.wrappedValue = false
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showConfirmCloseAlert) {
            Button("Discard", role: .destructive) {
                isPresented?.wrappedValue = false
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text(
                "You have unsaved changes. Are you sure you want to discard them?"
            )
        }
        .interactiveDismissDisabled(hasChanges)
    }

    private var hasChanges: Bool {
        return !viewModel.flightNumber.isEmpty || viewModel.selectedRoute != nil
            || viewModel.selectedAircraft != nil
            || !viewModel.selectedStaffIDs.isEmpty
    }

    private var registerButton: some View {
        Button(action: handleRegistration) {
            Text(viewModel.isEditMode ? "Update Trip" : "Schedule Trip")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    viewModel.fieldErrors.isEmpty
                        ? Color(.systemBlue) : Color(.systemBlue).opacity(0.6)
                )
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: UI
extension TripRegistrationContent {

    var aircraftPicker: some View {
        Menu {
            ForEach(availableAircraft, id: \.id) { ac in
                Button(ac.registrationNumber) {
                    viewModel.selectedAircraft = ac
                }
            }
        } label: {
            HStack {
                Text(
                    viewModel.selectedAircraft?.registrationNumber
                        ?? "Select aircraft"
                )
                .foregroundColor(
                    viewModel.selectedAircraft == nil
                        ? Color(.systemGray3) : Color.primary
                )
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12).fill(
                    Color(.systemGray6)
                )
            )
        }
    }

    var routePicker: some View {
        Menu {
            ForEach(routes, id: \.id) { route in
                Button(route.name) {
                    viewModel.selectedRoute = route
                }
            }
        } label: {
            HStack {
                Text(
                    viewModel.selectedRoute?.name ?? "Select route"
                )
                .foregroundColor(
                    viewModel.selectedRoute == nil
                        ? Color(.systemGray3) : Color.primary
                )
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12).fill(
                    Color(.systemGray6)
                ).stroke(Color(.systemGray2), lineWidth: 1)
            )
        }
    }

    var tripNumber: some View {
        FormInputField(
            label: "Trip Number",
            placeholder: "Enter trip number eg Trip - 001",
            focus: .flightNumber,
            hasError: viewModel.fieldErrors["flightNumber"] != nil,
            maxLength: 100,
            allowedCharacter: {
                $0.isLetter || $0.isNumber || $0.isWhitespace || $0 == "-"
            },
            text: $viewModel.flightNumber,
            focusedField: $focusedField
        )
    }

    var datePicker: some View {
        DatePicker(
            "Departure",
            selection: $viewModel.scheduledDeparture,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12).fill(
                Color(.systemGray6)
            ).stroke(Color(.systemGray2), lineWidth: 1)
        )
        .disabled(viewModel.isEditMode)
        .opacity(viewModel.isEditMode ? 0.6 : 1.0)
    }

    @ViewBuilder
    var staffSelector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Assign Crew")
                    .font(.headline)
                if staffs.isEmpty {
                    Text("No staff available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(availableStaffs, id: \.id) { staff in
                        HStack {
                            Toggle(
                                isOn: Binding(
                                    get: {
                                        viewModel.isSelected(staff)
                                    },
                                    set: { newVal in
                                        viewModel.toggleStaff(staff)
                                    }
                                )
                            ) {
                                HStack {
                                    staff.avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading) {
                                        Text(staff.name)
                                        Text(staff.designation.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .frame(maxHeight: 300)
    }

    var borderColor: Color {
        viewModel.selectedRoute != nil ? .blue : Color(.systemGray2)
    }
}

// MARK: Util
extension TripRegistrationContent {
    var tripEndDate: Date? {
        guard let route = viewModel.selectedRoute else { return nil }
        return viewModel.scheduledDeparture.addingTimeInterval(
            TimeInterval(route.totalPlannedDurationMinutes * 60)
        )
    }

    var availableStaffs: [Staff] {
        guard let endDate = tripEndDate else { return [] }

        return staffs.filter {
            $0.isAvailable(from: viewModel.scheduledDeparture, to: endDate)
        }
    }

    var availableAircraft: [Aircraft] {
        guard let endDate = tripEndDate, availableStaffs.count != 0 else {
            return []
        }

        var availableStaffByRole: [StaffRole: Int] = [:]
        availableStaffByRole[.cabinCrew] =
            availableStaffs.filter { $0.designation == .cabinCrew }.count
        availableStaffByRole[.pilot] =
            availableStaffs.filter { $0.designation == .pilot }.count
        availableStaffByRole[.coPilot] =
            availableStaffs.filter { $0.designation == .coPilot }.count

        return aircrafts.filter {
            $0.isAvailable(
                from: viewModel.scheduledDeparture,
                to: endDate,
                availableStaff: availableStaffByRole
            )
        }
    }

    private func handleRegistration() {
        guard viewModel.validate() else { return }

        // check minimum staff per role
        if let aircraft = viewModel.selectedAircraft {
            var selectedStaffRolesCount: [StaffRole: Int] = [:]
            for s in staffs {
                if viewModel.selectedStaffIDs.contains(s.id.uuidString) {
                    selectedStaffRolesCount[s.designation, default: 0] += 1
                }
            }

            for (role, minRequired) in aircraft.minimumStaffRequired {
                let have = selectedStaffRolesCount[role, default: 0]
                if have < minRequired {
                    viewModel.fieldErrors["staff"] =
                        "Require at least \(minRequired) \(role.rawValue)"
                    return
                }
            }
        }

        submit()
    }

    private func submit() {
        guard let route = viewModel.selectedRoute,
            let aircraft = viewModel.selectedAircraft
        else { return }

        let selectedStaff = staffs.filter {
            viewModel.selectedStaffIDs.contains($0.id.uuidString)
        }

        do {
            if viewModel.isEditMode, let tripToEdit = viewModel.tripToEdit {
                // Update existing trip
                tripToEdit.flightNumber = viewModel.flightNumber
                tripToEdit.route = route

            } else {
                // Create new trip
                let newTrip = Trip(
                    staff: selectedStaff,
                    aircraft: aircraft,
                    nodeStatuses: [],
                    route: route,
                    scheduledDepartureTime: viewModel.scheduledDeparture,
                    flightNumber: viewModel.flightNumber,
                    isCancelled: false
                )

                context.insert(newTrip)
                aircraft.trips.append(newTrip)
                for staff in selectedStaff {
                    staff.trips.append(newTrip)
                }
            }

            try context.save()
            let message =
                viewModel.isEditMode
                ? "Trip updated successfully" : "Trip scheduled successfully"
            notificationManager.showSuccess(message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented?.wrappedValue = false
                dismiss()
            }
        } catch {
            let message =
                viewModel.isEditMode
                ? "Failed to update trip. Please try again."
                : "Failed to schedule trip. Please try again."
            notificationManager.showError(message)
            print("Failed to save trip: \(error)")
        }
    }

}
