import SwiftData
import SwiftUI

struct TripRegistrationContent: View {
    @State var viewModel: TripRegistrationFormViewModel

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
                    Text("Schedule New Trip")
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()

                VStack(spacing: 12) {
                    tripNumber
                    datePicker

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

                    // Aircraft picker
                    Menu {
                        ForEach(aircrafts, id: \.id) { ac in
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
                    
                    
                    if viewModel.selectedRoute != nil {
                        staffSelector
                    }

                    // Validation errors
                    if let err = viewModel.fieldErrors["staff"] {
                        Text(err).foregroundColor(.red).font(.caption)
                    }

                    registerButton
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Trip Registration")
            .navigationBarTitleDisplayMode(.inline)
            .padding(.vertical)
        }
    }

    private var registerButton: some View {
        Button(action: handleRegistration) {
            Text("Schedule Trip")
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
    
    var tripNumber: some View {
        FormInputField(
            label: "Trip Number",
            placeholder: "Enter trip number",
            focus: .flightNumber,
            hasError: viewModel.fieldErrors["flightNumber"] != nil,
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

        let newTrip = Trip(
            staff: selectedStaff,
            aircraft: aircraft,
            nodeStatuses: [],
            route: route,
            scheduledDepartureTime: viewModel.scheduledDeparture,
            flightNumber: viewModel.flightNumber,
            isCancelled: false
        )

        do {
            context.insert(newTrip)
            // also attach to aircraft and staff collections
            aircraft.trips.append(newTrip)
            for s in selectedStaff {
                s.trips.append(newTrip)
            }
            try context.save()
            notificationManager.showSuccess("Trip scheduled successfully")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            notificationManager.showError("Failed to schedule trip. Please try again.")
            print("Failed to save trip: \(error)")
        }
    }

}
