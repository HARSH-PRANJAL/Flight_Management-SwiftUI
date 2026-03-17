import SwiftUI

struct CardView: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let iconColor: Color
    var clickable: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                        .padding(.bottom, 4)

                    Text(value)
                        .font(.title3)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(iconColor)
                    .minimumScaleFactor(0.7)
            }

            HStack(alignment: .bottom) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if clickable {
                Image(systemName: "chevron.right")
                    .font(.subheadline.smallCaps())
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.trailing, 12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 200)
        .background(cardTheme())
    }
}

#Preview {
    CardView(
        title: "On-Time Performance",
        value: "92%",
        subtitle: "Flights today",
        icon: "clock.fill",
        iconColor: Color(.blue)
    )
    .padding()
}
