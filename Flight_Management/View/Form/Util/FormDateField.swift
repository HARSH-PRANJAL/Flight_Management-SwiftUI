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

    // Stable anchor IDs for scroll targeting
    private let pickerBottomID = "form_date_picker_done"

    var allowedDateRange: ClosedRange<Date> {
        minDate...maxDate
    }

    private var borderColor: Color {
        if hasError { return Color(.systemRed) }
        return showDatePicker ? Color(.systemBlue) : Color.fieldBorder
    }

    private var isAcceptedDate: Bool {
        if datePickerComponents.contains(.hourAndMinute) {
            return allowedDateRange.contains(selectedDate)
        }
        return !Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        ScrollViewReader { proxy in
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

                    Image(
                        systemName: showDatePicker
                            ? "calendar.badge.minus" : "calendar"
                    )
                    .foregroundStyle(
                        showDatePicker
                            ? Color(.systemBlue) : Color.primary
                    )
                    .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.fieldFill)
                        .strokeBorder(borderColor, lineWidth: 1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDatePicker.toggle()
                    }
                    if !showDatePicker { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(pickerBottomID, anchor: .bottom)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(title2)
                .accessibilityValue(formatDate(selectedDate, format: format))
                .accessibilityHint(
                    "Tap to \(showDatePicker ? "close" : "open") date picker"
                )
                .accessibilityAddTraits(.isButton)

                if showDatePicker {
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
                        .padding(.horizontal, 8)

                        Divider()

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showDatePicker = false
                            }
                        } label: {
                            Text("Done")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(.systemBlue))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .id(pickerBottomID)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.fieldFill)
                            .strokeBorder(
                                Color(.systemBlue).opacity(0.4), lineWidth: 1
                            )
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .clipped()
                }
            }
        }
    }
}

#Preview {
    FormDateField(
        selectedDate: .constant(Date()),
        hasError: false,
        minDate: Calendar.current.date(
            byAdding: .year, value: -70, to: Date()
        ) ?? Date(),
        maxDate: Calendar.current.date(
            byAdding: .year, value: -16, to: Date()
        ) ?? Date(),
        datePickerComponents: [.date]
    )
    .padding()
}
