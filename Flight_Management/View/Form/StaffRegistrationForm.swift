import SwiftUI
import SwiftData

struct StaffRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    
    @State private var viewModel = StaffRegistrationFormViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            StaffRegistrationContent(viewModel: viewModel)
        }
        .overlay(alignment: .top) {
            successOverlay
        }
    }
    
    @ViewBuilder
    private var successOverlay: some View {
        if viewModel.submissionState == .success {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                Text("Staff added successfully")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Color.green.opacity(0.9))
            .clipShape(Capsule())
            .padding(.top, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    StaffRegistrationForm()
        .modelContainer(for: Staff.self, inMemory: true)
}
