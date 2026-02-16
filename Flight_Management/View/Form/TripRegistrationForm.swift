import SwiftUI
import SwiftData

struct TripRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel = TripRegistrationFormViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            TripRegistrationContent(viewModel: viewModel)
        }
    }
}

#Preview {
    TripRegistrationForm()
        .modelContainer(for: Trip.self, inMemory: true)
}
