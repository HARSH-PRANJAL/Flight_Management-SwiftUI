import SwiftUI

struct ActionButton: View {
    @State var isUnavailable: Bool
    var iconName1: String
    var iconName2: String
    var title1: String
    var title2: String
    let onActionButtonTapped: () -> Void

    var title: String {
        isUnavailable ? title1 : title2
    }
    var iconName: String {
        isUnavailable ? iconName1 : iconName2
    }
    var bgColor: Color {
        isUnavailable
            ? Color(.systemGreen).opacity(0.02)
            : Color(.systemRed).opacity(0.02)
    }
    var borderColor: Color {
        isUnavailable
            ? Color(.systemGreen).opacity(0.4) : Color(.systemRed).opacity(0.4)
    }
    var fgColor: Color {
        isUnavailable ? Color(.systemGreen) : Color(.systemRed)
    }

    var body: some View {
        Button {
            onActionButtonTapped()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))

                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(fgColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardTheme())
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bgColor)
        )
        .contentShape(Rectangle())
    }
}
