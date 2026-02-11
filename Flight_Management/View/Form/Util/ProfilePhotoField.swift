import PhotosUI
import SwiftUI

struct ProfilePhotoField: View {
    @State var viewModel: StaffRegistrationFormViewModel

    var body: some View {
        VStack(spacing: 12) {
            PhotosPicker(
                selection: $viewModel.selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                profileImageContent
            }

            Text("Add Photo")
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .onChange(of: viewModel.selectedPhoto) { _, newItem in
            guard let item = newItem else { return }
            Task {
                await viewModel.processPhoto(item)
            }
        }
    }

    @ViewBuilder
    private var profileImageContent: some View {
        ZStack(alignment: .bottomTrailing) {
            if let preview = viewModel.profilePreview {
                preview
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .photoOverlay()
            } else {
                defaultProfileImage
            }

            addPhotoButton
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundStyle(.gray.opacity(0.6))
            .photoOverlay()
    }

    private var addPhotoButton: some View {
        Image(systemName: "plus.circle.fill")
            .resizable()
            .frame(width: 36, height: 36)
            .foregroundStyle(.white, .blue)
            .background(Circle().fill(.white))
            .shadow(color: .blue.opacity(0.3), radius: 5)
            .offset(x: 6, y: 6)
    }
}

// MARK: - Circle Overlay Modifier
private struct PhotoOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.4),
                        lineWidth: 2
                    )
            }
            .shadow(radius: 2)
    }
}

extension View {
    fileprivate func photoOverlay() -> some View {
        modifier(PhotoOverlay())
    }
}

#Preview {
    @Previewable @State var viewModel = StaffRegistrationFormViewModel()
    return ProfilePhotoField(viewModel: viewModel)
}
