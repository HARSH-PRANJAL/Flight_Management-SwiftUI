import SwiftUI
import SwiftData

struct TripRegistrationForm: View {
    @State private var viewModel: TripRegistrationFormViewModel
    
    var isPresented: Binding<Bool>?

    init(isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: TripRegistrationFormViewModel())
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            TripRegistrationContent(viewModel: viewModel, isPresented: isPresented)
        }
    }
}

#Preview {
    TripRegistrationForm()
        .modelContainer(for: Trip.self, inMemory: true)
}
