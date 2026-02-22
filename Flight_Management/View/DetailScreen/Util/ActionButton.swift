import SwiftUI

/// Toggle-style action button (e.g. Mark Available/Unavailable) or destructive action (e.g. Cancel Trip).
enum ActionButtonStyle {
    case toggle(isPositiveState: Bool)  // positive = green, negative = red
    case destructive                    // red only
}

struct ActionButton: View {
    var style: ActionButtonStyle = .toggle(isPositiveState: false)
    var iconName: String
    var title: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var foregroundColor: Color {
        switch style {
        case .toggle(let isPositive):
            return isPositive ? Color(.systemGreen) : Color(.systemRed)
        case .destructive:
            return Color(.systemRed)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .toggle(let isPositive):
            return isPositive ? Color(.systemGreen).opacity(0.05) : Color(.systemRed).opacity(0.05)
        case .destructive:
            return cardTheme() as? Color ?? Color.clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .toggle(let isPositive):
            return isPositive ? Color(.systemGreen).opacity(0.4) : Color(.systemRed).opacity(0.4)
        case .destructive:
            return Color(.systemRed).opacity(0.4)
        }
    }
}
