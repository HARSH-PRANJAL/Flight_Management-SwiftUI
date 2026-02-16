import SwiftUI

@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    
    var notification: NotificationType = .none
    private var dismissTimer: Timer?
    
    func showSuccess(_ message: String) {
        notification = .success(message: message)
        scheduleDismissal()
    }
    
    func showError(_ message: String) {
        notification = .error(message: message)
        scheduleDismissal()
    }
    
    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        notification = .none
    }
    
    private func scheduleDismissal() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
}

struct NotificationView: View {
    let notificationType: NotificationType
    @Environment(NotificationManager.self) var notificationManager
    
    var body: some View {
        switch notificationType {
        case .success(let message):
            SuccessOverlay(message: message)
        case .error(let message):
            ErrorOverlay(message: message)
        case .none:
            EmptyView()
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack {
            Text("Content")
            Spacer()
        }
    }
    .overlay(alignment: .top) {
        NotificationView(notificationType: .success(message: "Operation successful"))
    }
    .environment(NotificationManager.shared)
}
