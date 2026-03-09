import SwiftUI

struct ClickableSection<Row: View, Destination: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let row: Row
    let destination: Destination

    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder row: () -> Row,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.row = row()
        self.destination = destination()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }

            NavigationLink(destination: destination) {
                HStack {
                    row

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
            }
            .buttonStyle(PressableRowStyle())
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct PressableRowStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {

        let backgroundColor: Color
        let pressedColor: Color

        if colorScheme == .dark {
            backgroundColor = Color(.secondarySystemBackground)
            pressedColor = Color(.systemGray4)
        } else {
            backgroundColor = Color(.tertiarySystemBackground)
            pressedColor = Color(.systemGray5)
        }

        return configuration.label
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? pressedColor : backgroundColor)
            )
            .animation(.easeOut(duration: 0.02),
                       value: configuration.isPressed)
    }
}
