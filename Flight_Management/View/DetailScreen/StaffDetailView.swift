import SwiftUI

struct StaffDetailView: View {
    let staff: Staff
    
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext
    
    @State var isEditPageShowing: Bool = false
    
    var isCurrentUser: Bool {
        session.user?.id == staff.id.uuidString
    }
    
    var profileImage: Image? {
        if let imageData = staff.profileImage,
            let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            DetailView(
                staff: staff,
                onTapAction: isCurrentUser ? { isEditPageShowing = true } : nil,
                actionButtonTitle: "Update Profile"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .bottomBar)
        }
        
        .sheet(isPresented: $isEditPageShowing) {
            StaffRegistrationForm(staff: staff, isPresented: $isEditPageShowing)
        }
    }
}

#Preview {
    NavigationStack {
        StaffDetailView(
            staff: Staff(
                name: "Captain John Doe",
                designation: .pilot,
                gender: .male,
                email: "john@example.com",
                dob: Date()
            )
        )
        .environment(SessionManager.shared)
    }
}

