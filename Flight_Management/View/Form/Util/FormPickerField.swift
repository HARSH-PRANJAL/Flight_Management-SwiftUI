import SwiftUI

struct FormPickerField<T: RawRepresentable & CaseIterable & Hashable>: View
where T.RawValue == String {
    let label: String
    let placeholder: String
    let focus: FormFocus
    let hasError: Bool

    @Binding var selection: T?
    @FocusState.Binding var focusedField: FormFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .formFieldLabel()

            Menu {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button(option.rawValue.capitalized) {
                        selection = option
                    }
                }
            } label: {
                menuLabel
            }
            .focused($focusedField, equals: focus)
        }
    }

    private var menuLabel: some View {
        HStack {
            Text(selection?.rawValue.capitalized ?? placeholder)
                .font(.system(size: 17))
                .foregroundColor(
                    selection == nil
                        ? Color(.systemGray3)
                        : Color(.label)
                )

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray3))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .stroke(borderColor, lineWidth: 1)
        }
        .shadow(
            color: Color.black.opacity(0.07),
            radius: 2,
            x: 0,
            y: 2
        )
    }

    private var borderColor: Color {
        if hasError {
            return Color(.systemRed)
        }
        return focusedField == focus ? Color(.systemBlue) : Color(.systemGray2)
    }
}

#Preview {
    @Previewable @State var selection: Gender? = nil
    @FocusState var focusedField: FormFocus?

    return FormPickerField<Gender>(
        label: "Gender",
        placeholder: "Select gender",
        focus: .gender,
        hasError: false,
        selection: $selection,
        focusedField: $focusedField
    )
}
