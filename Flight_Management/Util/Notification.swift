import SwiftUI

struct SuccessOverlay: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(.systemGreen))
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.systemGreen))
        }
        .padding()
        .clipShape(Capsule())
        .glassEffect(.regular.tint(Color(.systemGreen).opacity(0.25)))
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct ErrorOverlay: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(.systemRed))
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.systemRed))
        }
        .padding()
        .clipShape(Capsule())
        .glassEffect(.regular.tint(Color(.systemRed).opacity(0.25)))
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview("Success Overlay") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Form Content")
            Spacer()
        }
    }
    .overlay(alignment: .top) {
        SuccessOverlay(message: "Staff added successfully")
    }
}

#Preview("Error Overlay") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Form Content")
            Spacer()
        }
    }
    .overlay(alignment: .top) {
        ErrorOverlay(message: "Failed to add staff. Please try again.")
    }
}
