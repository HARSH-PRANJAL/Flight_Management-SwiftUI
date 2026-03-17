import SwiftData
import SwiftUI

struct RouteRegistrationForm: View {
    @State private var viewModel: RouteRegistrationFormViewModel
    
    var isPresented: Binding<Bool>?

    init(isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: RouteRegistrationFormViewModel())
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea(.all)
            RouteRegistrationContent(viewModel: viewModel, isPresented: isPresented)
                .onAppear {
                    viewModel.originalSnapshot = viewModel.currentSnapshot()
                }
                .padding(.bottom, 24)
        }
    }
}

#Preview {
    NavigationStack {
        RouteRegistrationForm()
            .modelContainer(for: [Route.self, Airport.self], inMemory: true)
    }
}
