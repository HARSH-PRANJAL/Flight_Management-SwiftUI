import SwiftUI
import UIKit

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


func dominantBackgroundColor(from image: UIImage) async -> UIColor? {
    guard let cgImage = image.cgImage else {
        print("❌ [dominantBackgroundColor] Failed: no cgImage")
        return nil
    }
    
    let width = cgImage.width
    let height = cgImage.height
    
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("❌ [dominantBackgroundColor] Failed: could not create CGContext")
        return nil
    }
    
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    context.draw(cgImage, in: rect)
    
    guard let data = context.data else {
        print("❌ [dominantBackgroundColor] Failed: no pixel data")
        return nil
    }
    
    let pixels = data.assumingMemoryBound(to: UInt8.self)
    let bytesPerRow = context.bytesPerRow
    
    let samplePoints = [
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1)
    ]
    
    var colors: [UIColor] = []
    
    for (x, y) in samplePoints {
        let offset = y * bytesPerRow + x * 4
        
        let r = CGFloat(pixels[offset]) / 255.0
        let g = CGFloat(pixels[offset + 1]) / 255.0
        let b = CGFloat(pixels[offset + 2]) / 255.0
        let a = CGFloat(pixels[offset + 3]) / 255.0
        
        colors.append(UIColor(red: r, green: g, blue: b, alpha: a))
    }
    
    let result = findMostCommonColor(colors)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    result.getRed(&r, green: &g, blue: &b, alpha: &a)
    print("✅ [dominantBackgroundColor] Extracted successfully: R=\(Int(r*255)) G=\(Int(g*255)) B=\(Int(b*255))")
    return result
}

private func findMostCommonColor(_ colors: [UIColor]) -> UIColor {
    var colorCounts: [String: (UIColor, Int)] = [:]
    
    for color in colors {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let key = "\(Int(r * 255))-\(Int(g * 255))-\(Int(b * 255))"
        
        if let (_, count) = colorCounts[key] {
            colorCounts[key] = (color, count + 1)
        } else {
            colorCounts[key] = (color, 1)
        }
    }
    
    return colorCounts.max(by: { $0.value.1 < $1.value.1 })?.value.0 ?? .gray
}
