import SwiftUI

struct FormErrorMessage: View {
    let error: String?
    
    var body: some View {
        if let error = error {
            Text(error)
                .font(.caption)
                .foregroundStyle(Color(.systemRed))
                .padding(.leading, 4)
        }
    }
}

#Preview {
    FormErrorMessage(error: "This field is required")
}