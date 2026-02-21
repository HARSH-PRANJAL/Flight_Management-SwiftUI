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
                .lineLimit(3)
        }
    }
}
