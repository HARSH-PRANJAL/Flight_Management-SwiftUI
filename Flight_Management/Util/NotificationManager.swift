import SwiftUI
import AVFoundation
import AudioToolbox

@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    
    var notification: NotificationType = .none
    private var dismissTimer: Timer?
    private let audioEngine = AudioEngine()
    
    deinit {
        dismissTimer?.invalidate()
    }
    
    func showSuccess(_ message: String) {
        notification = .success(message: message)
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

// MARK: notification
struct SuccessOverlay: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(.systemGreen))
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.systemGreen))
        }
        .padding()
        .clipShape(Capsule())
        .glassEffect(.clear.tint(Color(.systemGreen).opacity(0.05)))
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct ErrorOverlay: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(.systemRed))
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.systemRed))
        }
        .padding()
        .clipShape(Capsule())
        .glassEffect(.clear.tint(Color(.systemRed).opacity(0.05)))
        .padding(.top, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

