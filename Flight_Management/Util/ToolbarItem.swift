import SwiftUI

func profileHandlerToolbarItem(session: SessionManager) -> some ToolbarContent {

    var toolbarLabel: some View {
        Group {
            if let user = session.user,
                let imageData = user.profileImage,
                let uiImage = UIImage(
                    data: imageData
                )
            {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .foregroundStyle(.gray)
            }
        }
    }

    return ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button("Logout") {
                session.logout()
            }

            NavigationLink(
                "Profile",
                destination: {
                    UserDetailView()
                }
            )
        } label: {
            toolbarLabel
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
}
