import SwiftUI

struct CardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.system(size: 28, weight: .semibold))
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(
            LinearGradient(
                colors: [background, background.opacity(0.75), background.opacity(0.5)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        ))
    }
}

#Preview {
    CardView(
        title: "On-Time Performance",
        value: "92%",
        subtitle: "Flights today",
        icon: "clock.fill",
        iconColor: Color(.blue),
        background: Color(.systemBackground)
    )
    .padding()
}
