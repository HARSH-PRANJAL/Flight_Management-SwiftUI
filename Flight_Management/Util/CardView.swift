import SwiftUI

struct CardView: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .minimumScaleFactor(0.7)
            }

            if let subtitle = self.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .minimumScaleFactor(0.7)
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
