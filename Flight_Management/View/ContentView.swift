import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session

    var body: some View {
        if session.isLoggedIn, let user = session.user {
            NavigationStack {
                Group {
                    if user.role == UserRole.admin.rawValue {
                        AdminHome()
                    } else if user.role == UserRole.tripManager.rawValue {
                        TripManagerView()
                    }
                }
                .toolbar {
                    toolbarItem
                }
                .toolbarColorScheme(.none, for: .navigationBar)
            }
        } else {
            UserLoginForm()
        }
    }
}

// MARK: UI
extension ContentView {
    var toolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Logout") {
                    session.logout()
                }
                
                NavigationLink("Profile", destination: {
                    UserDetailView()
                })
            } label: {
                toolbarLabel
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
        }
    }
    
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
}

#Preview {
    ContentView()
        .environment(SessionManager.shared)
}
