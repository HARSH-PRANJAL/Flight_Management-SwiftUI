import SwiftUI

struct FormDateField: View {
    @State var viewModel: StaffRegistrationFormViewModel
    let hasError: Bool
    
    @FocusState.Binding var focusedField: FormFocus?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .formFieldLabel()
            
            HStack(spacing: 8) {
                FormDateComponentPicker(
                    options: viewModel.daysInMonth,
                    selection: $viewModel.day,
                    placeholder: "Day",
                    hasError: hasError
                )
                
                FormDateComponentPicker(
                    options: Array(Month.allCases).map(\.rawValue),
                    selection: $viewModel.month,
                    placeholder: "Month",
                    hasError: hasError
                )
                
                FormDateComponentPicker(
                    options: viewModel.years,
                    selection: $viewModel.year,
                    placeholder: "Year",
                    hasError: hasError
                )
            }
        }
    }
}

private struct FormDateComponentPicker: View {
    let options: [String]
    let selection: Binding<String>
    let placeholder: String
    let hasError: Bool
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection.wrappedValue = option
                }
            }
        } label: {
            HStack {
                Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                    .font(.system(size: 17))
                    .foregroundColor(
                        selection.wrappedValue.isEmpty
                            ? Color(.systemGray3)
                            : Color(.label)
                    )
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .stroke(
                        hasError ? Color(.systemRed) : Color(.systemGray3),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    @Previewable @State var viewModel = StaffRegistrationFormViewModel()
    @FocusState var focusedField: FormFocus?
    
    return FormDateField(
        viewModel: viewModel,
        hasError: false,
        focusedField: $focusedField
    )
}
