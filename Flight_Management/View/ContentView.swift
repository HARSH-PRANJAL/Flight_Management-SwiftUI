import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session
    @Environment(NotificationManager.self) var notificationManager

    var body: some View {
        ZStack {
            if session.isLoggedIn, let user = session.user {
                    Group {
                        if user.role == UserRole.admin.rawValue {
                            AdminHome()
                        } else if user.role == UserRole.tripManager.rawValue {
                            TripManagerHome()
                        }
                    }
            } else {
                UserLoginForm()
            }
            
            VStack {
                NotificationView(notificationType: notificationManager.notification)
                    .animation(.smooth, value: notificationManager.notification)
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(SessionManager.shared)
        .environment(NotificationManager.shared)
}
