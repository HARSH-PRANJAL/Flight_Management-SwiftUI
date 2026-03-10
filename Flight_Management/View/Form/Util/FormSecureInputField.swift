import SwiftUI

struct FormSecureInputField: View {
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

    @State private var isRevealed = false

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(label)
                .formFieldLabel()

            ZStack(alignment: .trailing) {

                inputField

                eyeButton
                    .contentShape(Rectangle())
            }
        }
    }
}

extension FormSecureInputField {

    fileprivate var inputField: some View {
        ZStack {
            SecureField(placeholder, text: $text)
                .opacity(isRevealed ? 0 : 1)

            TextField(placeholder, text: $text)
                .opacity(isRevealed ? 1 : 0)
        }
        .font(.system(size: 17))
        .padding(.trailing, 40)
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
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = focus
        }
    }

    var eyeButton: some View {
        Image(systemName: isRevealed ? "eye.fill" : "eye.slash.fill")
            .foregroundStyle(.secondary)
            .padding(.trailing, 12)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isRevealed {
                            isRevealed = true
                            focusedField = focus
                        }
                    }
                    .onEnded { _ in
                        isRevealed = false
                        focusedField = focus
                    }
            )
    }

    var borderColor: Color {
        if isDisabled {
            return Color(.systemGray5)
        }
        if hasError {
            return Color(.systemRed)
        }
        return focusedField == focus ? Color(.systemBlue) : Color(.systemGray2)
    }

    func sanitise(_ input: String) -> String {
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
