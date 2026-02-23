import Foundation
import SwiftUI

struct FormDateField: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false

    let hasError: Bool
    let minBirthDate: Date
    let maxBirthDate: Date

    var allowedDateRange: ClosedRange<Date> {
        maxBirthDate...minBirthDate
    }

    private var borderColor: Color {
        if hasError {
            return Color(.systemRed)
        }
        return Color(.systemGray2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .formFieldLabel()

            HStack {
                Text(formatDate(selectedDate, format: "d MMM yyyy"))
                    .foregroundStyle(
                        Calendar.current.isDateInToday(selectedDate)
                            ? Color(.systemGray3) : Color(.label)
                    )

                Spacer()

                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .strokeBorder(
                        borderColor,
                        lineWidth: 1
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showDatePicker = true
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Date of Birth")
            .accessibilityValue(formatDate(selectedDate, format: "d MMMM yyyy"))
            .accessibilityHint("Tap to change date")
            .accessibilityAddTraits(.isButton)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 0) {
                    DatePicker(
                        "Select date of birth",
                        selection: $selectedDate,
                        in: allowedDateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal)
                    .padding(.vertical, 24)

                    Spacer()
                }
                .navigationTitle("Date of Birth")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showDatePicker = false
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .foregroundStyle(
                            selectedDate != Date()
                                ? Color(.systemBlue) : Color(.systemGray3)
                        )
                    }
                }
            }
            .presentationDetents([.height(300), .medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    @FocusState var focusedField: FormFocus?

    FormDateField(
        selectedDate: .constant(Date()),
        hasError: false,
        minBirthDate: Date(),
        maxBirthDate: Date()
    )
}
