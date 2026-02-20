import SwiftUI

struct TripDetailRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let trip: Trip

    @State private var isClicked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } icon: {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }

            HStack {
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    ListRow(trip: trip)
                }
                .padding(12)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.smallCaps())
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.trailing, 12)
            }
            .background(cardTheme())
        }
    }
}
