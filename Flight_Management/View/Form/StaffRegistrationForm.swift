import SwiftData
import SwiftUI

struct StaffRegistrationForm: View {
    @State private var viewModel: StaffRegistrationFormViewModel
    
    var isPresented: Binding<Bool>?

    init(isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: StaffRegistrationFormViewModel())
        self.isPresented = isPresented
    }
    
    init(staff: Staff, isPresented: Binding<Bool>? = nil) {
        _viewModel = State(initialValue: StaffRegistrationFormViewModel(staff: staff))
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea(.all)
            StaffRegistrationContent(viewModel: viewModel, isPresented: isPresented)
                .navigationTitle(viewModel.isEditMode ? "Updated Staff" : "Add Staff")
                .navigationBarTitleDisplayMode(.inline)
                .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            viewModel.originalSnapshot = viewModel.currentSnapshot()
        }
    }
}

#Preview {
    StaffRegistrationForm()
        .modelContainer(for: Staff.self, inMemory: true)
}

