import SwiftUI

struct FormInputField: View {
    let label: String
    let placeholder: String
    let focus: FormFocus
    let hasError: Bool

    var maxLength: Int = 100
    var allowedCharacter: ((Character) -> Bool)? = nil
    var trimWhitespace: Bool = false
    var isDisabled: Bool = false

    @Binding var text: String
    @FocusState.Binding var focusedField: FormFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .formFieldLabel()
            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .padding(.trailing, maxLength < 100 ? 20 : 0)
                .autocorrectionDisabled()
                .disabled(isDisabled)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .stroke(borderColor, lineWidth: 1)
                }
                .focused($focusedField, equals: focus)
                .animation(.easeIn, value: borderColor)
                .onChange(of: text) { _, newValue in
                    let sanitised = sanitise(newValue)
                    if sanitised != newValue {
                        text = sanitised
                    }
                }
                .overlay(alignment: .trailing) {
                    if maxLength < 100 {
                        Text("\(text.count)/\(maxLength)")
                            .font(.caption2)
                            .foregroundStyle(
                                Double(text.count) < Double(maxLength) * 0.9
                                    ? Color.secondary : Color(.systemRed)
                            )
                            .padding(.trailing, 8)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = focus
                }
        }
    }

    private var borderColor: Color {
        if isDisabled {
            return Color(.systemGray5)
        }
        if hasError {
            return Color(.systemRed)
        }
        return focusedField == focus ? Color(.systemBlue) : Color(.systemGray2)
    }

    private func sanitise(_ input: String) -> String {
        var result = input

        if let allowed = allowedCharacter {
            result = String(result.filter { allowed($0) })
        }

        if trimWhitespace {
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if result.count > maxLength {
            result = String(result.prefix(maxLength))
        }

        return result
    }
}

#Preview {
    @Previewable @State var text = ""
    @FocusState var focusedField: FormFocus?

    FormInputField(
        label: "Name",
        placeholder: "Enter your name",
        focus: .name,
        hasError: false,
        maxLength: 10,
        allowedCharacter: { item in
            item.isLetter || item.isNumber
        },
        text: $text,
        focusedField: $focusedField
    )
}
