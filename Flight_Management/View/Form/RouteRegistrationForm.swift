import SwiftData
import SwiftUI

struct RouteRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel = RouteRegistrationFormViewModel()

    var body: some View {
        RouteRegistrationContent(viewModel: viewModel)
    }
}

#Preview {
    NavigationStack {
        RouteRegistrationForm()
            .modelContainer(for: [Route.self, Airport.self], inMemory: true)
    }
}
