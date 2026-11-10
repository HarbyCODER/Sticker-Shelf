import Foundation
import UIKit

enum StickerLibrary {
    static let directory = URL(fileURLWithPath: "/var/mobile/Library/StickerShelf", isDirectory: true)
    static let maximumStickerBytes = 500 * 1024

    static func prepare() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func files() -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .filter { ["png", "jpg", "jpeg", "gif"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    @discardableResult
    static func save(_ image: UIImage, name: String = UUID().uuidString) throws -> URL {
        try prepare()
        let data = try stickerPNGData(from: image)
        guard data.count < maximumStickerBytes else { throw StickerLibraryError.imageTooLarge }
        let safeName = name.replacingOccurrences(of: "/", with: "-")
        let url = directory.appendingPathComponent("\(safeName).png")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func remove(_ url: URL) throws {
        guard url.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static func stickerPNGData(from image: UIImage) throws -> Data {
        let width = CGFloat(image.cgImage?.width ?? Int(image.size.width * image.scale))
        let height = CGFloat(image.cgImage?.height ?? Int(image.size.height * image.scale))
        let sourceMax = max(width, height)
        guard sourceMax > 0 else { throw StickerLibraryError.invalidImage }

        for maximumSide: CGFloat in [618, 480, 360, 300, 240] {
            let factor = min(1, maximumSide / sourceMax)
            let size = CGSize(width: max(1, (width * factor).rounded()), height: max(1, (height * factor).rounded()))
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            if let data = resized.pngData(), data.count < maximumStickerBytes { return data }
        }
        throw StickerLibraryError.imageTooLarge
    }
}

enum StickerLibraryError: LocalizedError {
    case invalidImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Không đọc được ảnh này."
        case .imageTooLarge:
            return "Ảnh quá lớn để dùng làm sticker. Hãy chọn ảnh PNG nhỏ hơn."
        }
    }
}
