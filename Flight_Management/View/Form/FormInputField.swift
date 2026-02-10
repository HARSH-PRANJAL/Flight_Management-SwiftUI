import SwiftUI

struct FormInputField: View {
    let label: String
    let placeholder: String
    let focus: FormFocus
    let hasError: Bool
    
    @Binding var text: String
    @FocusState.Binding var focusedField: FormFocus?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .formFieldLabel()
            
            TextField(placeholder, text: $text)
                .font(.system(size: 17))
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
                .focused($focusedField, equals: focus)
        }
    }
    
    private var borderColor: Color {
        if hasError {
            return Color(.systemRed)
        }
        return focusedField == focus ? Color(.systemBlue) : Color(.systemGray3)
    }
}

#Preview {
    @State var text = ""
    @FocusState var focusedField: FormFocus?
    
    return FormInputField(
        label: "Name",
        placeholder: "Enter your name",
        focus: .name,
        hasError: false,
        text: $text,
        focusedField: $focusedField
    )
}