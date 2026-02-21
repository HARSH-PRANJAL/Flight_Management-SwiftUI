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
                HStack {
                    if !title.isEmpty {
                        Text(title)
                            .font(.headline)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                    }
                }
                .padding(20)

                Spacer()

                if let image = image {
                    Group {
                        if circular {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 320, height: 320)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.25), lineWidth: 2))
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
                
                Spacer()
            }
            .background(contentBackground)
        }
        .onAppear {
            if let c = profileBgColor {
                print("✅ [ImagePreviewer] Received profileBgColor: R=\(c.red) G=\(c.green) B=\(c.blue)")
            } else {
                print("⚠️ [ImagePreviewer] No profileBgColor - using default background")
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
