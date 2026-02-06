import SwiftUI

struct customFloatingTextField: View {
    var title: String
    @Binding var text: String
    @FocusState private var isTyping: Bool

    var body: some View {

        ZStack(alignment: .leading) {
            TextField("", text: $text)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 45)
                .focused($isTyping)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .stroke(
                            isTyping ? Color.blue : Color(.systemGray),
                            lineWidth: 2
                        )
                )

            Text(title)
                .foregroundStyle(
                    isTyping ? .blue : Color.primary
                )
                .background {
                    Color(
                        isTyping || !text.isEmpty
                            ? .systemBackground : .systemGray6
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.leading)
                .offset(y: isTyping || !text.isEmpty ? -27 : 0)
                .onTapGesture {
                    isTyping.toggle()
                }
        }
        .animation(.linear(duration: 0.2), value: isTyping)
    }
}
