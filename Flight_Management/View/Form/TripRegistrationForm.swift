import SwiftUI
import SwiftData

struct TripRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel: TripRegistrationFormViewModel
    
    var isPresented: Binding<Bool>?

    init(isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: TripRegistrationFormViewModel())
        self.isPresented = isPresented
    }
    
    init(trip: Trip, isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: TripRegistrationFormViewModel(trip: trip))
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
