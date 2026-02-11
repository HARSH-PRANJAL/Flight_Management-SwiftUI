import SwiftData
import SwiftUI

struct StaffRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel = StaffRegistrationFormViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            StaffRegistrationContent(viewModel: viewModel)
        }
    }
}

#Preview {
    StaffRegistrationForm()
        .modelContainer(for: Staff.self, inMemory: true)
}
