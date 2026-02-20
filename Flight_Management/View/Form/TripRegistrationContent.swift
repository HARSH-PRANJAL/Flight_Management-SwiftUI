import SwiftData
import SwiftUI

struct TripRegistrationContent: View {
    @State var viewModel: TripRegistrationFormViewModel

    var isPresented: Binding<Bool>?
    @State private var showConfirmCloseAlert = false
    @State private var currentDetent: PresentationDetent = .large

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
                    routePicker
                    datePicker
                    withAnimation(.easeOut(duration: 0.5)) {
                        Group {
                            if !availableStaffs.isEmpty
                                && !availableAircraft.isEmpty
                            {
                                aircraftPicker
                                crewSelectors
                            }
                        }
                    }

                    if let err = viewModel.fieldErrors["staff"] {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
                .padding(.horizontal)

                Spacer()
                disclaimerText
            }
            .navigationTitle("Schedule Trip")
            .navigationBarTitleDisplayMode(.inline)
            .padding(.vertical)
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
                    isPresented?.wrappedValue = false
                }
            }
        }
        .toolbar {
            closeToolbarButton
            submitToolbarButton
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
    }
}

// MARK: UI
extension TripRegistrationContent {

    var closeToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
                if viewModel.isDirty {
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

    var submitToolbarButton: some ToolbarContent {
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

    @ViewBuilder
    var aircraftPicker: some View {
        Menu {
            ForEach(availableAircraft, id: \.id) { aircraft in
                Button(aircraft.registrationNumber) {
                    viewModel.selectedAircraft = aircraft
                }
            }
        } label: {
            HStack {
                Text(
                    viewModel.selectedAircraft?.registrationNumber
                        ?? "Select Aircraft"
                )
                .foregroundColor(
                    viewModel.selectedAircraft == nil
                        ? Color(.systemGray3) : Color.primary
                )
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .strokeBorder(Color(.systemGray2), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
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
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .strokeBorder(Color(.systemGray2), lineWidth: 1)
            }
        }
    }

    var tripNumber: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Trip Number",
                placeholder: "Enter trip number eg Trip - 001",
                focus: .flightNumber,
                hasError: viewModel.fieldErrors["flightNumber"] != nil,
                allowedCharacter: {
                    $0.isLetter || $0.isNumber || $0.isWhitespace || $0 == "-"
                },
                text: $viewModel.flightNumber,
                focusedField: $focusedField
            )

            FormErrorMessage(error: viewModel.fieldErrors["flightNumber"])
        }
    }

    var datePicker: some View {
        DatePicker(
            "Departure",
            selection: $viewModel.scheduledDeparture,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .strokeBorder(
                    Color(.systemGray2),
                    lineWidth: 1
                )
        }
    }

    var crewSelectors: some View {
        HStack(spacing: 12) {
            pilotPicker
            coPilotPicker
            crewMemberPicker
        }
    }

    @ViewBuilder
    var pilotPicker: some View {
        Menu {
            ForEach(availableStaffByRole(.pilot), id: \.id) { staff in
                Button(staff.name) {
                    viewModel.selectedPilot = staff
                }
            }
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text(
                    viewModel.selectedPilot?.name ?? "Pilot"
                )
                .font(.caption2)
                .foregroundColor(
                    viewModel.selectedPilot == nil
                        ? Color(.systemGray3) : Color.primary
                )
                .lineLimit(1)
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGray3))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    var coPilotPicker: some View {
        Menu {
            ForEach(availableStaffByRole(.coPilot), id: \.id) { staff in
                Button(staff.name) {
                    viewModel.selectedCoPilot = staff
                }
            }
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text(
                    viewModel.selectedCoPilot?.name ?? "Co-Pilot"
                )
                .font(.caption2)
                .foregroundColor(
                    viewModel.selectedCoPilot == nil
                        ? Color(.systemGray3) : Color.primary
                )
                .lineLimit(1)
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGray3))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .transaction { $0.animation = nil }
    }

    @ViewBuilder
    var crewMemberPicker: some View {
        Menu {
            ForEach(availableStaffByRole(.cabinCrew), id: \.id) { staff in
                Button(staff.name) {
                    viewModel.selectedCrewMember = staff
                }
            }
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text(
                    viewModel.selectedCrewMember?.name ?? "Crew"
                )
                .font(.caption2)
                .foregroundColor(
                    viewModel.selectedCrewMember == nil
                        ? Color(.systemGray3) : Color.primary
                )
                .lineLimit(1)
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGray3))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .transaction { $0.animation = nil }
    }

    private var disclaimerText: some View {
        Text(
            "Trip information will be recorded in the system for scheduling and staff assignment."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.top, 16)
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

    var isFormValid: Bool {
        !viewModel.flightNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty && viewModel.selectedRoute != nil
            && viewModel.selectedAircraft != nil
            && viewModel.selectedPilot != nil
            && viewModel.selectedCoPilot != nil
            && viewModel.selectedCrewMember != nil
    }

    var availableAircraft: [Aircraft] {
        guard let endDate = tripEndDate else {
            return []
        }

        return aircrafts.filter { aircraft in
            // Check if aircraft is available during the trip
            let isTimeAvailable = !aircraft.scheduledTrips.contains(where: {
                $0.estimatedArrivalTime > viewModel.scheduledDeparture
                    && $0.scheduledDepartureTime < endDate
            })

            guard isTimeAvailable else { return false }

            // Check if aircraft minimum staff requirements can be met with our selection
            // We're assigning exactly 1 pilot, 1 copilot, 1 cabin crew
            // So aircraft should require <= 1 of each role
            for (role, minRequired) in aircraft.minimumStaffRequired {
                if minRequired > 1 {
                    return false
                }
            }

            // Ensure at least 1 staff of each required role is available
            for (role, minRequired) in aircraft.minimumStaffRequired {
                let availableCount = availableStaffByRole(role).count
                if availableCount < minRequired {
                    return false
                }
            }

            return true
        }
    }

    func availableStaffByRole(_ role: StaffRole) -> [Staff] {
        return availableStaffs.filter { $0.designation == role }
    }

    private func handleRegistration() {
        guard viewModel.validate() else { return }

        // Validate that selected aircraft minimum staff requirements can be met
        if let aircraft = viewModel.selectedAircraft {
            let selectedStaffByRole: [StaffRole: Int] = [
                .pilot: viewModel.selectedPilot != nil ? 1 : 0,
                .coPilot: viewModel.selectedCoPilot != nil ? 1 : 0,
                .cabinCrew: viewModel.selectedCrewMember != nil ? 1 : 0,
            ]

            for (role, minRequired) in aircraft.minimumStaffRequired {
                let assigned = selectedStaffByRole[role] ?? 0
                if minRequired > assigned {
                    viewModel.fieldErrors["staff"] =
                        "Aircraft requires \(minRequired) \(role.rawValue) but only \(assigned) assigned"
                    return
                }
            }
        }

        submit()
    }

    private func submit() {
        guard let route = viewModel.selectedRoute,
            let aircraft = viewModel.selectedAircraft,
            let pilot = viewModel.selectedPilot,
            let coPilot = viewModel.selectedCoPilot,
            let crewMember = viewModel.selectedCrewMember
        else { return }

        let selectedStaff = [pilot, coPilot, crewMember]

        do {
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

            try context.save()
            notificationManager.showSuccess("Trip scheduled successfully")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented?.wrappedValue = false
                dismiss()
            }
        } catch {
            notificationManager.showError(
                "Failed to schedule trip. Please try again."
            )
            print("Failed to save trip: \(error)")
        }
    }

}
