import SwiftUI

struct NavigationListSection<Item: Identifiable, Destination: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [Item]
    let rowContent: (Item) -> AnyView
    let destination: (Item) -> Destination

    init(
        title: String,
        icon: String,
        iconColor: Color = Color(.systemBlue),
        items: [Item],
        @ViewBuilder rowContent: @escaping (Item) -> some View,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.items = items
        self.rowContent = { AnyView(rowContent($0)) }
        self.destination = destination
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        NavigationLink(destination: destination(item)) {
                            rowContent(item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.smallCaps())
                            .foregroundStyle(Color(.tertiaryLabel))
                            .padding(.trailing, 12)
                    }
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(cardTheme())
        }
        .padding(.bottom, 16)
    }
}
