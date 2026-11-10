import Messages
import UIKit

final class StickerShelfExtensionController: MSMessagesAppViewController, MSStickerBrowserViewDataSource {
    private var browser: MSStickerBrowserView!
    private var stickers: [MSSticker] = []
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        browser = MSStickerBrowserView(frame: view.bounds, stickerSize: .regular)
        browser.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        browser.dataSource = self
        view.addSubview(browser)

        emptyLabel.text = "Thêm sticker trong ứng dụng StickerShelf"
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
        reloadStickers()
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        reloadStickers()
    }

    private func reloadStickers() {
        stickers = StickerLibrary.files().compactMap { url in
            guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  size < StickerLibrary.maximumStickerBytes else { return nil }
            return try? MSSticker(contentsOfFileURL: url, localizedDescription: url.deletingPathExtension().lastPathComponent)
        }
        emptyLabel.isHidden = !stickers.isEmpty
        browser?.reloadData()
    }

    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        stickers.count
    }

    func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        stickers[index]
    }
}
