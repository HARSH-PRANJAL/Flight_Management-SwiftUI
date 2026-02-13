import PhotosUI
import SwiftUI

@MainActor
func handleImageData(_ data: Data, photo: inout Data?) -> Image? {
    if let image = UIImage(data: data),
        let compressed = image.jpegData(compressionQuality: 0.78)
    {
        photo = compressed
        return Image(uiImage: UIImage(data: compressed) ?? image)
    } else {
        photo = data
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
}
