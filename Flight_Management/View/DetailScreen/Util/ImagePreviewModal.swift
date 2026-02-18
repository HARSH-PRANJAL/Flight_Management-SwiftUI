import SwiftUI

struct ImagePreviewModal: View {
    @Environment(\.dismiss) var dismiss
    
    var image: Image?
    var title: String = ""
    
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
                    image
                        .resizable()
                        .scaledToFit()
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
    ImagePreviewModal(
        image: Image(systemName: "person.crop.circle.fill"),
        title: "Profile Photo"
    )
}
