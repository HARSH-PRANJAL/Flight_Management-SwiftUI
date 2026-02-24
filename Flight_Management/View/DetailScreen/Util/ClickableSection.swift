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
        }
    }
}

struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        configuration.isPressed
                            ? Color(.systemGray5)
                            : Color(.tertiarySystemBackground)
                    )
            )
            .animation(
                .easeInOut(duration: 0.02),
                value: configuration.isPressed
            )
    }
}
