import SwiftData
import SwiftUI

struct TripRegistrationContent: View {

    @State var viewModel: TripRegistrationFormViewModel
    var isPresented: Binding<Bool>?

    @State private var showConfirmCloseAlert = false
    @State private var showConfirmSaveAlert = false
    @State private var currentDetent: PresentationDetent = .large
    @State private var activeSheet: ActiveSheet?

    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Route> { $0.isActive }, sort: \.name)
    private var routes: [Route]
    @Query(filter: #Predicate<Aircraft> { !$0.isDecommissioned }) private var aircrafts: [Aircraft]
    @Query private var staffs: [Staff]

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                tripNumberField
                routePicker
                datePicker

                if !viewModel.availableStaffs.isEmpty
                    && viewModel.hasAvailableAircraft
                {
                    aircraftPicker
                }

                if viewModel.selectedAircraft != nil {
                    crewSelectors
                }

                if let err = viewModel.fieldErrors["staff"] {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 20)

            disclaimerText
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Schedule Trip")
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
            viewModel.fieldErrors.removeValue(forKey: "aircraft")
        }
        .onChange(of: viewModel.selectedRoute) { _, _ in
            viewModel.recomputeAvailability(
                staffs: staffs,
                aircrafts: aircrafts
            )
        }
        .onChange(of: viewModel.scheduledDeparture) { _, _ in
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
            Button("Discard", role: .destructive) {
                close()
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
            .foregroundStyle(
                viewModel.isDirty
                    ? Color(.systemBlue)
                    : Color(.systemGray3)
            )
        }
    }

    private var tripNumberField: some View {
        FormInputField(
            label: "Trip Number",
            placeholder: "Trip-001",
            focus: .flightNumber,
            hasError: viewModel.fieldErrors["flightNumber"] != nil,
            maxLength: 50,
            allowedCharacter: {
                $0.isLetter || $0.isNumber || $0 == "-"
            },
            text: $viewModel.flightNumber,
            focusedField: $focusedField
        )
    }

    @ViewBuilder
    private var routePicker: some View {
        let sortedRoute = routes.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Route").formFieldLabel()

            Menu {
                ForEach(sortedRoute, id: \.id) { route in
                    Button(route.name) {
                        viewModel.selectedRoute = route
                    }
                }
            } label: {
                pickerLabel(
                    viewModel.selectedRoute?.name ?? "Select Route",
                    isEmpty: viewModel.selectedRoute == nil
                )
            }
        }
    }

    private var datePicker: some View {
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
            ) ?? .distantFuture,
            datePickerComponents: [.date, .hourAndMinute]
        )
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
                    isEmpty: viewModel.selectedAircraft == nil
                )
            }
        }
    }

    private var crewSelectors: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Crew").formFieldLabel()

            HStack(spacing: 12) {

                if viewModel.selectedAircraft?.minimumStaffRequired[.pilot]
                    ?? 0 > 0
                {
                    crewButton(.pilot, "Pilot")
                }
                if viewModel.selectedAircraft?.minimumStaffRequired[
                    .coPilot
                ] ?? 0 > 0 {
                    crewButton(.coPilot, "Co-Pilot")
                }
                if viewModel.selectedAircraft?.minimumStaffRequired[
                    .cabinCrew
                ] ?? 0 > 0 {
                    crewButton(.cabinCrew, "Crew")
                }
            }
        }
    }

    private func crewButton(_ role: StaffRole, _ title: String)
        -> some View
    {
        Button {
            activeSheet = .staff(role: role)
        } label: {
            pickerLabel(
                Self.crewLabel(
                    selected: selectedStaff(for: role),
                    emptyTitle: title
                ),
                isEmpty: selectedStaff(for: role).isEmpty
            )
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

    private func pickerLabel(_ text: String, isEmpty: Bool)
        -> some View
    {
        HStack {
            Text(text)
                .foregroundColor(
                    isEmpty ? Color(.systemGray3) : .primary
                )
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color(.systemGray3))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .strokeBorder(Color(.systemGray2), lineWidth: 1)
        )
    }

    private func selectedStaff(for role: StaffRole) -> [Staff] {
        switch role {
        case .pilot: return viewModel.selectedPilots
        case .coPilot: return viewModel.selectedCoPilots
        case .cabinCrew: return viewModel.selectedCrewMembers
        }
    }

    private func selectedStaffBinding(for role: StaffRole)
        -> Binding<[Staff]>
    {
        switch role {
        case .pilot:
            return $viewModel.selectedPilots
        case .coPilot:
            return $viewModel.selectedCoPilots
        case .cabinCrew:
            return $viewModel.selectedCrewMembers
        }
    }

    private static func crewLabel(
        selected: [Staff],
        emptyTitle: String
    ) -> String {
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
        submit()
    }

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

        try? context.save()

        notificationManager.showSuccess("Trip scheduled successfully")
        close()
    }

    private var disclaimerText: some View {
        Text(
            "Trip information will be recorded for scheduling and staff assignment."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.top, 16)
    }
}
