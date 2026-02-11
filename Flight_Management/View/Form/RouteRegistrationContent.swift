import SwiftData
import SwiftUI

struct RouteRegistrationContent: View {
    @State var viewModel: RouteRegistrationFormViewModel
    @State var isAirportRegistrationFormDisplayed = false

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

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

                saveButton
                disclaimerText
            }
            .navigationTitle("Create Route")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAirportRegistrationFormDisplayed, content: {
                AirportRegistrationForm()
            })
        }
    }

    // MARK: - Form Sections
    private var routeNameFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            FormInputField(
                label: "Route Name",
                placeholder: "e.g., East Coast Loop",
                focus: .routeName,
                hasError: viewModel.fieldErrors[.routeName] != nil,
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
                    ForEach(
                        Array(viewModel.selectedNodes.enumerated()),
                        id: \.element.id
                    ) { index, node in
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
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Trip")
                                        .font(
                                            .system(size: 12, weight: .semibold)
                                        )
                                        .foregroundColor(Color(.systemGray))

                                    HStack(spacing: 4) {
                                        TextField(
                                            "0",
                                            text: Binding(
                                                get: {
                                                    node.journeyTimeMinutes
                                                },
                                                set: {
                                                    viewModel.updateJourneyTime(
                                                        at: index,
                                                        minutes: $0
                                                    )
                                                }
                                            )
                                        )
                                        .font(
                                            .system(size: 16, weight: .semibold)
                                        )
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 40)

                                        Text("min")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(.systemGray))
                                    }
                                }

                                // Remove Button
                                Button(action: {
                                    viewModel.removeAirport(at: index)
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

                            if index < viewModel.selectedNodes.count - 1 {
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
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .opacity(viewModel.selectedNodes.isEmpty ? 0.5 : 1)

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
                        .fill(Color(.systemGray6))
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.07),
                    radius: 2,
                    x: 0,
                    y: 2
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
                    .fill(Color(.systemGray6))
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.07),
                radius: 2,
                x: 0,
                y: 2
            )
        }
    }

    private var saveButton: some View {
        Button(action: handleSave) {
            Text("Save Route")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBlue))
                .cornerRadius(12)
                .glassEffect(in: .rect)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
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

    private func handleSave() {
        if viewModel.saveRoute(to: context) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RouteRegistrationContent(viewModel: RouteRegistrationFormViewModel())
            .modelContainer(for: [Route.self, Airport.self], inMemory: true)
    }
}
