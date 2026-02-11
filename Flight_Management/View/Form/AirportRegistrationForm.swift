import SwiftData
import SwiftUI

struct AirportRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel = AirportRegistrationFormViewModel()

    var body: some View {
        AirportRegistrationContent(viewModel: viewModel)
    }
}

#Preview {
    NavigationStack {
        AirportRegistrationForm()
            .modelContainer(for: Airport.self, inMemory: true)
    }
}
