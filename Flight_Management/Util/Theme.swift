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


