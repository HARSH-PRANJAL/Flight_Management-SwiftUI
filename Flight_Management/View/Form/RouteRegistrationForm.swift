import SwiftData
import SwiftUI

struct RouteRegistrationForm: View {
    @State private var viewModel: RouteRegistrationFormViewModel
    
    var isPresented: Binding<Bool>?

    init(isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: RouteRegistrationFormViewModel())
        self.isPresented = isPresented
    }
    
    init(route: Route, isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: RouteRegistrationFormViewModel(route: route))
        self.isPresented = isPresented
    }

    var body: some View {
        RouteRegistrationContent(viewModel: viewModel, isPresented: isPresented)
            .onAppear {
                viewModel.originalSnapshot = viewModel.currentSnapshot()
            }
    }
}

#Preview {
    NavigationStack {
        RouteRegistrationForm()
            .modelContainer(for: [Route.self, Airport.self], inMemory: true)
    }
}
