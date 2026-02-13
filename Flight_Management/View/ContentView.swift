import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session

    var body: some View {
        if session.isLoggedIn, let user = session.user {
            if user.role == UserRole.admin.rawValue {
                AdminHome()
            } else {
                EmptyView()
            }
        } else {
            UserLoginForm()
        }
    }
}

#Preview {
    ContentView()
        .environment(SessionManager.shared)
}
