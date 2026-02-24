import SwiftUI

struct CardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(value)
                        .font(.title)
                        .fontWeight(.semibold)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
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
