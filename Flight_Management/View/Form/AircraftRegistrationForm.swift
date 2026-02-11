import SwiftData
import SwiftUI

struct AircraftRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel = AircraftRegistrationFormViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            AircraftRegistrationContent(viewModel: viewModel)
        }
        .navigationTitle("Aircraft Registration")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.submissionState == .error {
                ErrorOverlay(message: "Aircraft can not be registered.")
            } else if viewModel.submissionState == .success {
                SuccessOverlay(message: "Aircraft registered.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        AircraftRegistrationForm()
            .modelContainer(for: Aircraft.self, inMemory: true)
    }
}
