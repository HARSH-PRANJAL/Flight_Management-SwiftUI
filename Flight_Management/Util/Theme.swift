import SwiftUI

func cardTheme() -> some View {
    Color(.tertiarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: Color.black.opacity(0.07),
            radius: 2,
            x: 0,
            y: 2
        )
}

struct DetailRowView: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundStyle(Color(.systemGray))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(2)
        }
    }
}

@ViewBuilder
func tripCards(title: String, count: Int, trips: [Trip], imageName: String, imageColor: Color) -> some View {
    VStack(alignment: .leading, spacing: 10) {
            Label {
                HStack(spacing: 0) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(" (\(count))")
                        .font(.footnote)
                        .fontWeight(.light)
                    Spacer()
                }
            } icon: {
                Image(systemName: imageName)
                    .foregroundStyle(imageColor)
            }
            .padding(.horizontal, 16)

        Group {
            ForEach(trips, id: \.id) { trip in
                HStack {
                    NavigationLink(destination: {
                        TripDetailView(trip: trip)
                    }, label: {
                        ListRow(trip: trip)
                    })
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(.systemGray4))
                        .padding(.trailing, 16)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.leading, 16)
        .background(
            cardTheme()
        )
    }
}
