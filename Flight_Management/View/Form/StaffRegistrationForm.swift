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
            Color(.systemGroupedBackground).ignoresSafeArea(.all)
            StaffRegistrationContent(viewModel: viewModel, isPresented: isPresented)
                .navigationBarTitle(viewModel.isEditMode ? "Updated Staff" : "Add Staff")
                .navigationBarTitleDisplayMode(.inline)
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

