import SwiftUI
import SwiftData

struct TripRegistrationForm: View {
    @State private var viewModel: TripRegistrationFormViewModel

    var isPresented: Binding<Bool>?

    // Add mode
    init(isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: TripRegistrationFormViewModel())
        self.isPresented = isPresented
    }

    // Edit mode
    init(trip: Trip, isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: TripRegistrationFormViewModel(trip: trip))
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            TripRegistrationContent(viewModel: viewModel, isPresented: isPresented)
                .navigationTitle(viewModel.isEditMode ? "Edit Trip" : "Schedule Trip")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.originalSnapshot = viewModel.currentSnapshot()
        }
    }
}
