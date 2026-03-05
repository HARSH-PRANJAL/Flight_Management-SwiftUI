import SwiftData
import SwiftUI

struct TripRegistrationContent: View {

    @State var viewModel: TripRegistrationFormViewModel
    var isPresented: Binding<Bool>?
    private let minDepartureDate = Date()
    private let maxDepartureDate =
        Calendar.current.date(byAdding: .year, value: 1, to: Date())
        ?? .distantFuture

    @State private var showConfirmCloseAlert = false
    @State private var currentDetent: PresentationDetent = .large
    @State private var activeSheet: ActiveSheet?

    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<Route> { $0.isActive },
        sort: [SortDescriptor(\.name, comparator: .localizedStandard)]
    )
    private var routes: [Route]
    @Query(filter: #Predicate<Aircraft> { !$0.isDecommissioned })
    private var aircrafts: [Aircraft]
    @Query(filter: #Predicate<Staff> { !$0.isMarkedUnavailable })
    private var staffs: [Staff]

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if !viewModel.isEditMode {
                    tripNumberField
                    routePicker
                    datePicker
                }

                if !viewModel.availableStaffs.isEmpty
                    && viewModel.hasAvailableAircraft
                {
                    aircraftPicker
                }

                if viewModel.selectedAircraft != nil {
                    crewSelectors
                }

                FormErrorMessage(error: viewModel.fieldErrors[.staff])
            }
            .padding(.horizontal)

            Spacer(minLength: 20)

            disclaimerText
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.large, .height(650)], selection: $currentDetent)
        .interactiveDismissDisabled(viewModel.isDirty)
        .onChange(of: currentDetent) { _, newValue in
            if newValue == .height(650) {
                if viewModel.isDirty {
                    showConfirmCloseAlert = true
                    currentDetent = .large
                } else {
                    close()
                }
            }
        }
        .onChange(of: viewModel.selectedAircraft) { _, _ in
            viewModel.selectedPilots = []
            viewModel.selectedCoPilots = []
            viewModel.selectedCrewMembers = []
            viewModel.fieldErrors.removeValue(forKey: .aircraft)
        }
        .onChange(of: viewModel.selectedRoute) { _, _ in
            viewModel.fieldErrors.removeValue(forKey: .route)
            viewModel.recomputeAvailability(
                staffs: staffs,
                aircrafts: aircrafts
            )
        }
        .onChange(of: viewModel.scheduledDeparture) { _, _ in
            viewModel.fieldErrors.removeValue(forKey: .date)
            viewModel.recomputeAvailability(
                staffs: staffs,
                aircrafts: aircrafts
            )
        }
        .toolbar {
            closeToolbarButton
            submitToolbarButton
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .aircraft:
                AircraftSelectorView(
                    allAircraft: viewModel.availableAircraft,
                    selectedAircraft: $viewModel.selectedAircraft
                )
            case .staff(let role):
                StaffSelectorView(
                    role: role,
                    requiredCount: viewModel.selectedAircraft?
                        .minimumStaffRequired[role] ?? 0,
                    allStaff: viewModel.availableStaffs
                        .filter { $0.designation == role },
                    selectedStaff: selectedStaffBinding(for: role)
                )
            }
        }
        .alert("Discard Changes?", isPresented: $showConfirmCloseAlert) {
            Button("Discard", role: .destructive) { close() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text(
                "You have unsaved changes. Are you sure you want to discard them?"
            )
        }
        .task {
            viewModel.recomputeAvailability(
                staffs: staffs,
                aircrafts: aircrafts
            )
        }
    }
}

// MARK: UI
extension TripRegistrationContent {

    var closeToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                if viewModel.isDirty {
                    showConfirmCloseAlert = true
                } else {
                    close()
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
            .foregroundStyle(
                viewModel.isDirty ? Color(.systemBlue) : Color(.systemGray3)
            )
        }
    }

    private var tripNumberField: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Trip Number",
                placeholder: "Trip-001",
                focus: .flightNumber,
                hasError: viewModel.fieldErrors[.flightNumber] != nil,
                maxLength: 50,
                allowedCharacter: { $0.isLetter || $0.isNumber || $0 == "-" },
                text: $viewModel.flightNumber,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.flightNumber) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .flightNumber)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.flightNumber])
        }
    }

    @ViewBuilder
    private var routePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Route").formFieldLabel()
            Menu {
                ForEach(routes, id: \.id) { route in
                    Button(route.name) {
                        viewModel.selectedRoute = route
                    }
                }
            } label: {
                pickerLabel(
                    viewModel.selectedRoute?.name ?? "Select Route",
                    isEmpty: viewModel.selectedRoute == nil,
                    hasError: viewModel.fieldErrors[.route] != nil
                )
            }

            FormErrorMessage(error: viewModel.fieldErrors[.route])
        }
    }

    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormDateField(
                selectedDate: $viewModel.scheduledDeparture,
                title: "Departure",
                title2: "Departure date & time",
                format: "dd/MM/yyyy h:mm",
                hasError: viewModel.fieldErrors[.date] != nil,
                minDate: minDepartureDate,
                maxDate: maxDepartureDate,
                datePickerComponents: [.date, .hourAndMinute]
            )

            FormErrorMessage(error: viewModel.fieldErrors[.date])
        }
    }

    private var aircraftPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Aircraft").formFieldLabel()
            Button {
                activeSheet = .aircraft
            } label: {
                pickerLabel(
                    viewModel.selectedAircraft?.registrationNumber
                        ?? "Select Aircraft",
                    isEmpty: viewModel.selectedAircraft == nil,
                    hasError: viewModel.fieldErrors[.aircraft] != nil
                )
            }

            FormErrorMessage(error: viewModel.fieldErrors[.aircraft])
        }
    }

    private var crewSelectors: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Crew").formFieldLabel()
            HStack(spacing: 12) {
                if viewModel.selectedAircraft?.minimumStaffRequired[.pilot] ?? 0
                    > 0
                {
                    crewButton(.pilot, "Pilot")
                }
                if viewModel.selectedAircraft?.minimumStaffRequired[.coPilot]
                    ?? 0 > 0
                {
                    crewButton(.coPilot, "Co-Pilot")
                }
                if viewModel.selectedAircraft?.minimumStaffRequired[.cabinCrew]
                    ?? 0 > 0
                {
                    crewButton(.cabinCrew, "Crew")
                }
            }
        }
    }

    private func crewButton(_ role: StaffRole, _ title: String) -> some View {
        Button {
            activeSheet = .staff(role: role)
            viewModel.fieldErrors.removeValue(forKey: .staff)
        } label: {
            pickerLabel(
                Self.crewLabel(
                    selected: selectedStaff(for: role),
                    emptyTitle: title
                ),
                isEmpty: selectedStaff(for: role).isEmpty,
                hasError: viewModel.fieldErrors[.staff] != nil
            )
            .lineLimit(1)
        }
    }
}

// MARK: Util
extension TripRegistrationContent {

    private enum ActiveSheet: Identifiable {
        case aircraft
        case staff(role: StaffRole)

        var id: String {
            switch self {
            case .aircraft: return "aircraft"
            case .staff(let role): return "staff-\(role)"
            }
        }
    }

    private func pickerLabel(
        _ text: String,
        isEmpty: Bool,
        hasError: Bool = false
    ) -> some View {
        HStack {
            Text(text)
                .foregroundColor(isEmpty ? Color(.systemGray3) : .primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color(.systemGray3))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .strokeBorder(
                    hasError ? Color(.systemRed) : Color(.systemGray2),
                    lineWidth: 1
                )
        )
        .animation(.easeIn, value: hasError)
    }

    private func selectedStaff(for role: StaffRole) -> [Staff] {
        switch role {
        case .pilot: return viewModel.selectedPilots
        case .coPilot: return viewModel.selectedCoPilots
        case .cabinCrew: return viewModel.selectedCrewMembers
        }
    }

    private func selectedStaffBinding(for role: StaffRole) -> Binding<[Staff]> {
        switch role {
        case .pilot: return $viewModel.selectedPilots
        case .coPilot: return $viewModel.selectedCoPilots
        case .cabinCrew: return $viewModel.selectedCrewMembers
        }
    }

    private static func crewLabel(selected: [Staff], emptyTitle: String)
        -> String
    {
        if selected.isEmpty { return emptyTitle }
        if selected.count == 1 { return selected[0].name }
        return "\(selected.count) \(emptyTitle)s"
    }

    private func close() {
        isPresented?.wrappedValue = false
        dismiss()
    }

    private func handleRegistration() {
        let minRequired =
            viewModel.selectedAircraft?.minimumStaffRequired ?? [:]
        guard viewModel.validate(minRequired: minRequired) else { return }

        if viewModel.isEditMode {
            updateTrip()
        } else {
            submit()
        }
    }

    // MARK: Create
    private func submit() {
        guard let route = viewModel.selectedRoute,
            let aircraft = viewModel.selectedAircraft
        else { return }

        let selectedStaff = viewModel.allSelectedStaff

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
        selectedStaff.forEach { $0.trips.append(newTrip) }

        do {
            try context.save()
            notificationManager.showSuccess("Trip scheduled successfully")
            close()
        } catch {
            notificationManager.showError(
                "Failed to save trip. Please try again."
            )
        }
    }

    // MARK: Update (Edit Mode)
    private func updateTrip() {
        guard let trip = viewModel.tripToEdit,
            let newAircraft = viewModel.selectedAircraft
        else { return }

        let oldAircraft = trip.aircraft
        let oldStaff = trip.staffs
        let newStaff = viewModel.allSelectedStaff

        if oldAircraft.id != newAircraft.id {
            oldAircraft.trips.removeAll { $0.id == trip.id }
            if oldAircraft.nextScheduledTrip?.id == trip.id {
                oldAircraft.updateNextScheduledTrip(after: trip)
            }
            newAircraft.trips.append(trip)
            trip.aircraft = newAircraft
        }

        let removedStaff = oldStaff.filter { old in
            !newStaff.contains { $0.id == old.id }
        }
        removedStaff.forEach { staff in
            staff.trips.removeAll { $0.id == trip.id }
            if staff.nextScheduledTrip?.id == trip.id {
                staff.updateNextScheduledTrip(after: trip)
            }
        }

        let addedStaff = newStaff.filter { new in
            !oldStaff.contains { $0.id == new.id }
        }
        addedStaff.forEach { $0.trips.append(trip) }

        trip.staffs = newStaff

        do {
            try context.save()
            notificationManager.showSuccess("Trip updated successfully")
            close()
        } catch {
            notificationManager.showError(
                "Failed to update trip. Please try again."
            )
        }
    }

    private var disclaimerText: some View {
        Text(
            viewModel.isEditMode
                ? "Only aircraft and crew can be changed for a scheduled trip."
                : "Trip information will be recorded for scheduling and staff assignment."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.top, 16)
    }
}
