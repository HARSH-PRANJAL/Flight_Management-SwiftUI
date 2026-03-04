import SwiftData
import SwiftUI

struct RouteRegistrationContent: View {
    @State var viewModel: RouteRegistrationFormViewModel
    @State var isAirportRegistrationFormDisplayed = false
    @State private var showConfirmCloseAlert = false
    @State private var showConfirmSaveAlert = false
    @State private var currentDetent: PresentationDetent = .large

    var isPresented: Binding<Bool>?

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(NotificationManager.self) var notificationManager

    @FocusState private var focusedField: FormFocus?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    routeNameFieldSection
                    airportsSection
                    routeSummarySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)

                Spacer()
                disclaimerText
            }
            .navigationTitle(
                "Add Route"
            )
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel.routeName.isEmpty {
                    focusedField = .routeName
                }
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
            .sheet(
                isPresented: $isAirportRegistrationFormDisplayed,
                content: {
                    NavigationStack {
                        AirportRegistrationContent(
                            isPresented: $isAirportRegistrationFormDisplayed
                        )
                    }
                }
            )
            .toolbar {
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

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        if self.validateAll() {
                            showConfirmSaveAlert = true
                        }
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
            .alert("Add route?", isPresented: $showConfirmSaveAlert) {
                Button("Add", role: .destructive) {
                    handleSave()
                    isPresented?.wrappedValue = false
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text(
                    "After saving, this route can’t be edited."
                )
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: UI
extension RouteRegistrationContent {
    private var routeNameFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Route Name",
                placeholder: "e.g., East Coast Loop",
                focus: .routeName,
                hasError: viewModel.fieldErrors[.routeName] != nil,
                maxLength: 50,
                allowedCharacter: {
                    $0.isLetter || $0.isWhitespace || $0 == "-"
                },
                text: $viewModel.routeName,
                focusedField: $focusedField
            )
            .onChange(of: viewModel.routeName) { _, _ in
                viewModel.fieldErrors.removeValue(forKey: .routeName)
            }

            FormErrorMessage(error: viewModel.fieldErrors[.routeName])
        }
    }

    private var airportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Airports")
                .formFieldLabel()

            // Search Dropdown
            AirportSearchDropdown(
                onAirportSelected: { airport in
                    viewModel.addAirport(airport)
                },
                excludeAirports: viewModel.selectedNodes.map { $0.airport }
            )

            // Selected Airports List
            if !viewModel.selectedNodes.isEmpty {
                VStack(spacing: 0) {
                    ForEach($viewModel.selectedNodes, id: \.id) { $node in
                        VStack(spacing: 0) {
                            HStack {
                                // Airport Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(node.airport.code)
                                        .font(
                                            .system(size: 16, weight: .semibold)
                                        )
                                        .foregroundColor(Color(.label))

                                    Text(node.airport.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.systemGray))
                                }

                                Spacer()

                                // Journey Time Input
                                if node.id != viewModel.selectedNodes.first?.id
                                {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Trip")
                                            .font(
                                                .system(
                                                    size: 12,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundColor(Color(.systemGray))

                                        HStack(spacing: 4) {
                                            TextField(
                                                "0",
                                                text: textBinding(for: node)
                                            )
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 8)
                                            .frame(minWidth: 50)
                                            .background(
                                                RoundedRectangle(
                                                    cornerRadius: 12
                                                )
                                                .fill(
                                                    Color(
                                                        .secondarySystemBackground
                                                    )
                                                )
                                                .strokeBorder(
                                                    Color(.systemGray2),
                                                    lineWidth: 1
                                                )
                                            )
                                            .contentShape(Rectangle())

                                            Text("min")
                                                .font(.system(size: 14))
                                                .foregroundColor(
                                                    Color(.systemGray)
                                                )
                                        }
                                    }
                                }

                                // Remove Button
                                Button(action: {
                                    viewModel.removeAirport(node)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(
                                            .system(size: 14, weight: .semibold)
                                        )
                                        .foregroundColor(Color(.systemGray2))
                                        .padding(8)
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            if node.id != viewModel.selectedNodes.last?.id {
                                Divider()
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }

            Button(action: {
                isAirportRegistrationFormDisplayed = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add another airport")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(.systemBlue))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(Color(.systemBlue))

            FormErrorMessage(error: viewModel.fieldErrors[.airports])
            FormErrorMessage(error: viewModel.fieldErrors[.journeyTime])
        }
    }

    private var routeSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Summary")
                .formFieldLabel()

            Text(viewModel.routeSummary)
                .foregroundColor(Color(.label))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )

            HStack {
                Text("Total trip duration")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))

                Spacer()

                Text("\(viewModel.totalDuration) min")
                    .foregroundColor(Color(.label))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
    }

    private var disclaimerText: some View {
        Text(
            "Routes will be available for trip scheduling and crew assignment."
        )
        .font(.system(size: 13))
        .foregroundColor(Color(.systemGray))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 30)
    }
}

// MARK: Util
extension RouteRegistrationContent {

    func validateAll() -> Bool {
        if !isNameUnique() {
            viewModel.fieldErrors[.routeName] =
                "A route with this name already exists."
            return false
        }
        
        var isValid = true

        isValid = viewModel.validateRouteName() && isValid
        isValid = viewModel.validateAirports() && isValid
        isValid = viewModel.validateJourneyTimes() && isValid

        return isValid
    }

    private func isNameUnique() -> Bool {
        if viewModel.routeName.isEmpty {
            return true
        }

        let routeName = Route.normalisedSearchKey(from: viewModel.routeName)
        let descriptor = FetchDescriptor<Route>(
            predicate: #Predicate<Route> { $0.nameSearchKey == routeName }
        )

        do {
            let result = try context.fetch(descriptor)
            return result.isEmpty
        } catch {
            return true
        }
    }

    private func textBinding(for node: RouteNodeData) -> Binding<String> {
        Binding(
            get: {
                viewModel.selectedNodes
                    .first(where: { $0.id == node.id })?
                    .journeyTimeMinutes ?? ""
            },
            set: { newValue in
                guard
                    viewModel.selectedNodes.contains(where: { $0.id == node.id }
                    )
                else {
                    return
                }
                viewModel.updateJourneyTime(for: node, minutes: newValue)
            }
        )
    }

    private func handleSave() {
        if viewModel.saveRoute(to: context) {
            let message = "Route added successfully"
            notificationManager.showSuccess(message)
            isPresented?.wrappedValue = false
            dismiss()
        } else {
            let message = "Failed to add route. Please try again."
            notificationManager.showError(message)
        }
    }
}

#Preview {
    NavigationStack {
        RouteRegistrationContent(viewModel: RouteRegistrationFormViewModel())
            .modelContainer(for: [Route.self, Airport.self], inMemory: true)
            .environment(NotificationManager.shared)
    }
}
