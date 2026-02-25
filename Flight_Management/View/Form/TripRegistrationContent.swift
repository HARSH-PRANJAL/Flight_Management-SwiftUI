import SwiftData
import SwiftUI

struct TripRegistrationContent: View {
    @State var viewModel: TripRegistrationFormViewModel

    var isPresented: Binding<Bool>?
    @State private var showConfirmCloseAlert = false
    @State private var showConfirmSaveAlert = false
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
            VStack(alignment: .leading, spacing: 20) {
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
        .alert("Schedule Trip?", isPresented: $showConfirmSaveAlert) {
            Button("Save", role: .destructive) {
                handleRegistration()
                isPresented?.wrappedValue = false
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text(
                "After saving, this trip can’t be edited and only be cancelled."
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
                if viewModel.validate(
                    minRequired: viewModel.selectedAircraft?
                        .minimumStaffRequired ?? [:]
                ) {
                    showConfirmSaveAlert = true
                }
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
        VStack(alignment: .leading, spacing: 4) {
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
                        .strokeBorder(
                            viewModel.fieldErrors.keys.contains("aircraft")
                                ? Color(.systemRed) : Color(.systemGray2),
                            lineWidth: 1
                        )
                }
            }
            .onChange(of: viewModel.selectedAircraft) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: "aircraft")
            }

            FormErrorMessage(error: viewModel.fieldErrors["aircraft"])
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
    var routePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                        .strokeBorder(
                            viewModel.fieldErrors.keys.contains("route")
                                ? Color(.systemRed) : Color(.systemGray2),
                            lineWidth: 1
                        )
                }
            }
            .onChange(of: viewModel.selectedRoute) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: "route")
            }

            FormErrorMessage(error: viewModel.fieldErrors["route"])
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
            .onChange(of: viewModel.flightNumber) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: "flightNumber")
            }

            FormErrorMessage(error: viewModel.fieldErrors["flightNumber"])
        }
    }

    @ViewBuilder
    var datePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormDateField(
                selectedDate: $viewModel.scheduledDeparture,
                title: "Departure",
                title2: "Departure date & time",
                format: "dd/MM/yyyy h:mm",
                hasError: false,
                minDate: Date(),
                maxDate: Calendar.current.date(
                    byAdding: .year,
                    value: 1,
                    to: Date()
                ) ?? Date.distantFuture,
                datePickerComponents: [.date, .hourAndMinute]
            )
            .onChange(of: viewModel.scheduledDeparture) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: "departureDate")
            }

            FormErrorMessage(error: viewModel.fieldErrors["departureDate"])
        }
    }

    @ViewBuilder
    var pilotPicker: some View {
        Menu {
            ForEach(viewModel.selectedPilots, id: \.id) { staff in
                Button(staff.name) {
                    viewModel.removeStaff(staff, role: .pilot)
                }
            }
            if !viewModel.selectedPilots.isEmpty
                && !availableStaffByRole(.pilot).isEmpty
            {
                Divider()
            }
            ForEach(availableStaffByRole(.pilot), id: \.id) { staff in
                if !viewModel.selectedPilots.contains(where: {
                    $0.id == staff.id
                }) {
                    Button(staff.name) {
                        viewModel.addStaff(staff, role: .pilot)
                    }
                }
            }
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text(
                    Self.crewLabel(
                        selected: viewModel.selectedPilots,
                        emptyTitle: "Pilot"
                    )
                )
                .font(.caption2)
                .foregroundColor(
                    viewModel.selectedPilots.isEmpty
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
            ForEach(viewModel.selectedCoPilots, id: \.id) { staff in
                Button(staff.name) {
                    viewModel.removeStaff(staff, role: .coPilot)
                }
            }
            if !viewModel.selectedCoPilots.isEmpty
                && !availableStaffByRole(.coPilot).isEmpty
            {
                Divider()
            }
            ForEach(availableStaffByRole(.coPilot), id: \.id) { staff in
                if !viewModel.selectedCoPilots.contains(where: {
                    $0.id == staff.id
                }) {
                    Button(staff.name) {
                        viewModel.addStaff(staff, role: .coPilot)
                    }
                }
            }
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text(
                    Self.crewLabel(
                        selected: viewModel.selectedCoPilots,
                        emptyTitle: "Co-Pilot"
                    )
                )
                .font(.caption2)
                .foregroundColor(
                    viewModel.selectedCoPilots.isEmpty
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
    var crewMemberPicker: some View {
        Menu {
            ForEach(viewModel.selectedCrewMembers, id: \.id) { staff in
                Button(staff.name) {
                    viewModel.removeStaff(staff, role: .cabinCrew)
                }
            }
            if !viewModel.selectedCrewMembers.isEmpty
                && !availableStaffByRole(.cabinCrew).isEmpty
            {
                Divider()
            }
            ForEach(availableStaffByRole(.cabinCrew), id: \.id) { staff in
                if !viewModel.selectedCrewMembers.contains(where: {
                    $0.id == staff.id
                }) {
                    Button(staff.name) {
                        viewModel.addStaff(staff, role: .cabinCrew)
                    }
                }
            }
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text(
                    Self.crewLabel(
                        selected: viewModel.selectedCrewMembers,
                        emptyTitle: "Crew"
                    )
                )
                .font(.caption2)
                .foregroundColor(
                    viewModel.selectedCrewMembers.isEmpty
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
            "Trip information will be recorded in the system for trip scheduling and staff assignment."
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

    private static func crewLabel(selected: [Staff], emptyTitle: String)
        -> String
    {
        if selected.isEmpty { return emptyTitle }
        if selected.count == 1 { return selected[0].name }
        return "\(selected.count) \(emptyTitle)s"
    }

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

    var availableStaffCountsByRole: [StaffRole: Int] {
        [
            .pilot: availableStaffByRole(.pilot).count,
            .coPilot: availableStaffByRole(.coPilot).count,
            .cabinCrew: availableStaffByRole(.cabinCrew).count,
        ]
    }

    var availableAircraft: [Aircraft] {
        guard let endDate = tripEndDate else { return [] }
        let availableStaff = availableStaffCountsByRole
        return aircrafts.filter { aircraft in
            aircraft.isAvailable(
                from: viewModel.scheduledDeparture,
                to: endDate,
                availableStaff: availableStaff
            )
        }
    }

    func availableStaffByRole(_ role: StaffRole) -> [Staff] {
        return availableStaffs.filter { $0.designation == role }
    }

    private func handleRegistration() {
        let minRequired =
            viewModel.selectedAircraft?.minimumStaffRequired ?? [:]
        guard viewModel.validate(minRequired: minRequired) else { return }
        submit()
    }

    private func submit() {
        guard let route = viewModel.selectedRoute,
            let aircraft = viewModel.selectedAircraft
        else { return }
        let selectedStaff = viewModel.allSelectedStaff

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
            isPresented?.wrappedValue = false
            dismiss()
        } catch {
            notificationManager.showError(
                "Failed to schedule trip. Please try again."
            )
            print("Failed to save trip: \(error)")
        }
    }

}
