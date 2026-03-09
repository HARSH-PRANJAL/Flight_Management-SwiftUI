import SwiftUI

struct DetailRowView: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .minimumScaleFactor(0.7)
                .lineLimit(5)
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .minimumScaleFactor(0.7)
                .lineLimit(5)
        }
    }
}
