import Foundation
import SwiftUI

struct FormDateField: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false

    var title: String = "Date of birth"
    var title2: String = "Select date of birth"
    var format: String = "d MMMM yyyy"
    var hasError: Bool
    let minDate: Date
    let maxDate: Date
    var datePickerComponents: DatePickerComponents = [.date]

    var allowedDateRange: ClosedRange<Date> {
        minDate...maxDate
    }

    private var borderColor: Color {
        if hasError {
            return Color(.systemRed)
        }
        return Color(.systemGray2)
    }

    private var isAcceptedDate: Bool {
        if datePickerComponents.contains(.hourAndMinute) {
            return selectedDate > Date()
        }
        return !Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .formFieldLabel()

            HStack {
                Text(formatDate(selectedDate, format: format))
                    .foregroundStyle(
                        isAcceptedDate
                        ? Color(.label) : Color(.systemGray3)
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
            .accessibilityLabel(title2)
            .accessibilityValue(formatDate(selectedDate, format: format))
            .accessibilityHint("Tap to change date")
            .accessibilityAddTraits(.isButton)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 0) {
                    DatePicker(
                        title2,
                        selection: $selectedDate,
                        in: allowedDateRange,
                        displayedComponents: datePickerComponents
                    )
                    .environment(\.locale, Locale(identifier: "en_GB"))
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal)
                    .padding(.vertical, 24)

                    Spacer()
                }
                .navigationTitle(title2)
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
        minDate: Date(),
        maxDate: Date(),
        datePickerComponents: [.date]
    )
}
