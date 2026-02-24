import SwiftUI

struct ClickableTripSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let trip: Trip

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

            NavigationLink(destination: TripDetailView(trip: trip)) {
                HStack {
                    ListRow(trip: trip)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
            }
            .buttonStyle(PressableRowStyle())   // 👈 custom style
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
            .animation(.easeInOut(duration: 0.02), value: configuration.isPressed)
    }
}
