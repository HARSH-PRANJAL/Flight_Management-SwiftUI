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
        }.shadow(
            color: Color.black.opacity(0.07),
            radius: 2,
            x: 0,
            y: 2
        )
    }

    private var menuLabel: some View {
        HStack {
            Text(selection?.rawValue.capitalized ?? placeholder)
                .lineLimit(1)
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .strokeBorder(borderColor, lineWidth: 1)
        }
    }
    
    var borderColor: Color {
        hasError ? Color(.systemRed) : Color(.systemGray2)
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
