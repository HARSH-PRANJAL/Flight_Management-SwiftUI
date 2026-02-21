import SwiftUI

struct ImagePreviewer: View {
    @Environment(\.dismiss) var dismiss

    var image: Image?
    var title: String = ""
    var circular: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

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
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
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
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    ImagePreviewer(
        image: Image(systemName: "person.crop.circle.fill"),
        title: "Profile Photo"
    )
}
