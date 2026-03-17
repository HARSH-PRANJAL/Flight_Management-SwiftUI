import SwiftUI

struct ImagePreviewer: View {
    @Environment(\.dismiss) var dismiss

    var image: Image?
    var title: String = ""
    var circular: Bool = false
    var profileBgColor: ColorData? = nil

    private var contentBackground: Color {
        if let profileBgColor {
            profileBgColor.swiftUIColor.opacity(0.25)
        } else {
            Color(.systemGroupedBackground)
        }
    }

    var body: some View {
        ZStack {
            contentBackground
                .ignoresSafeArea(.all)
                VStack {
                    if let image = image {
                        Group {
                            if circular {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 320, height: 320)
                                    .padding(16)
                            } else {
                                image
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .padding(20)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(.gray)
                            Text("No Image Available")
                                .foregroundStyle(.gray)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
    }
}

#Preview {
    ImagePreviewer(
        image: Image(systemName: "person.crop.circle.fill"),
        title: "Profile Photo"
    )
}
