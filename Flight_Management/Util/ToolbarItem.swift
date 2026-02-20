import SwiftData
import SwiftUI

func profileHandlerToolbarItem(
    session: SessionManager,
    modelContext: ModelContext
) -> some ToolbarContent {
    return ToolbarItem(placement: .topBarTrailing) {
        Menu {
            NavigationLink(
                "Profile",
                destination: {
                    UserDetailView()
                }
            )
            Section {
                Button("Logout", role: .destructive) {
                    session.logout()
                }
                .buttonSizing(.flexible)
                .buttonStyle(.plain)
            }
        } label: {
            ToolbarLabel()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
}

struct ToolbarLabel: View {
    @Environment(SessionManager.self) var session
    @Environment(\.modelContext) var modelContext

    @State var user: User?
    var body: some View {
        Group {
            if let imageData = user?.profileImage,
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
        .onAppear {
            Task {
                if session.isLoggedIn {
                    user = await session.getUserFromDB(
                        modelContext: modelContext
                    )
                }
            }
        }
    }
}
