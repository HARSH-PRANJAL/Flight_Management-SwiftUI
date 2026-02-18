import SwiftUI

func fallbackStaffImage() -> some View {
    return Image(systemName: "person.circle.fill")
        .symbolRenderingMode(.palette)
        .resizable()
        .scaledToFit()
        .foregroundStyle(Color(.systemGray3), Color(.systemBackground))
}

func fallbackNoStaffDataImage() -> Image {
    return Image(systemName: "person.slash")
        .symbolRenderingMode(.monochrome)
}
