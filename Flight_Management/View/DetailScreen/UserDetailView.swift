import SwiftData
import SwiftUI

struct UserDetailView: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext
    
    @State var isEditPageShowing: Bool = false
    @State var userToEdit: User? = nil
    
    var profileImage: Image? {
        if let user = session.user,
            let imageData = user.profileImage,
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
                profileImage: profileImage,
                titleText: session.user?.name ?? "Unknown User",
                subTitleText: session.user?.role ?? "Unknown Designation",
                statusBadge: nil,
                listData: [],
                onActionButtonTapped: {
                    handleEditButtonTapped()
                },
                actionButtonTitle: "Update Profile"
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollDisabled(true)
            .toolbar(.hidden, for: .bottomBar)
        }
        
        .sheet(isPresented: $isEditPageShowing) {
            UserRegistrationForm(
                isPresented: $isEditPageShowing,
                editForm: true,
                user: userToEdit
            )
        }
    }
    
    private func handleEditButtonTapped() {
        guard let userIdString = session.user?.id,
              let userUUID = UUID(uuidString: userIdString) else { return }

        do {
            let predicate = #Predicate<User> { $0.id == userUUID }
            let descriptor = FetchDescriptor<User>(predicate: predicate, sortBy: [])
            let results = try modelContext.fetch(descriptor)

            if let fetchedUser = results.first {
                userToEdit = fetchedUser
                isEditPageShowing = true
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "person.crop.circle.fill")!
    let sampleData = sampleImage.pngData()

    SessionManager.shared.user = LoggedInUser(
        id: "123",
        name: "Hp",
        role: "Admin",
        profileImage: sampleData
    )
    return UserDetailView()
        .environment(SessionManager.shared)
}
