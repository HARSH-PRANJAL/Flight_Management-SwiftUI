import SwiftData
import SwiftUI

struct AirportRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @State private var viewModel = AirportRegistrationFormViewModel()
    
    var isPresented: Binding<Bool>?

    var body: some View {
        AirportRegistrationContent(viewModel: viewModel, isPresented: isPresented ?? .constant(false))
    }
}

#Preview {
    NavigationStack {
        AirportRegistrationForm()
            .modelContainer(for: Airport.self, inMemory: true)
    }
}
