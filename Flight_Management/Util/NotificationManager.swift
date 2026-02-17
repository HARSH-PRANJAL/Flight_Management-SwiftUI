import SwiftUI
import AVFoundation
import AudioToolbox

@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    
    var notification: NotificationType = .none
    private var dismissTimer: Timer?
    private let audioEngine = AudioEngine()
    
    func showSuccess(_ message: String) {
        notification = .success(message: message)
//        playSuccessSound()
//        triggerSuccessHaptic()
        scheduleDismissal()
    }
    
    func showError(_ message: String) {
        notification = .error(message: message)
        playErrorSound()
        triggerErrorHaptic()
        scheduleDismissal()
    }
    
    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        notification = .none
    }
    
    private func scheduleDismissal() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    private func playSuccessSound() {
        audioEngine.playErrorSound()
    }
    
    private func playErrorSound() {
        audioEngine.playErrorSound()
    }
    
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func triggerErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

final class AudioEngine {
    func playSuccessSound() {
        AudioServicesPlaySystemSound(1021)
    }
    
    func playErrorSound() {
        AudioServicesPlaySystemSound(1051)
    }
}

struct NotificationView: View {
    let notificationType: NotificationType
    
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
