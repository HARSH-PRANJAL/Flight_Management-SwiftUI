import SwiftData
import SwiftUI

struct UserDetailView: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var context
    
    @State var isEditPageShowing: Bool = false
    @State var user: User? = nil
    
    var profileImage: Image? {
        if let user = user,
            let imageData = user.profileImage,
            let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "person")
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            DetailView(
                profileImage: profileImage,
                titleText: user?.name ?? "Unknown User",
                subTitleText: user?.role.rawValue ?? "Unknown Designation",
                detailText: user?.email,
                statusBadge: nil,
                listData: [],
                onActionButtonTapped: {
                    isEditPageShowing.toggle()
                },
                actionButtonTitle: "Update Profile"
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollDisabled(true)
            .toolbar(.hidden, for: .bottomBar)
        }
        .sheet(isPresented: $isEditPageShowing) {
            NavigationStack {
                UserRegistrationForm(
                    isPresented: $isEditPageShowing
                )
            }
        }
        .task {
            if session.isLoggedIn == true {
                user = await session.getUserFromDB(modelContext: context)
            }
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
