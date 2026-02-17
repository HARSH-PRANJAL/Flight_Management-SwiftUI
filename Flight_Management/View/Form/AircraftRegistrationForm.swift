import SwiftData
import SwiftUI

struct AircraftRegistrationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    @Binding var isSheetVisible: Bool
    @State private var viewModel = AircraftRegistrationFormViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            AircraftRegistrationContent(viewModel: viewModel, isPresented: $isSheetVisible)
        }
        .navigationTitle("Aircraft Registration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AircraftRegistrationForm(isSheetVisible: .constant(false))
            .modelContainer(for: Aircraft.self, inMemory: true)
    }
}
