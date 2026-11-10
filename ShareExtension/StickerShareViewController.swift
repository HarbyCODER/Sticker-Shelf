import UIKit
import UniformTypeIdentifiers

final class StickerShareViewController: UIViewController {
    private let messageLabel = UILabel()
    private let doneButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 320, height: 220)

        messageLabel.text = "Đang lưu sticker…"
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .headline)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        doneButton.setTitle("Đóng", for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        doneButton.isHidden = true
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(messageLabel)
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -18),
            doneButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        importSharedImages()
    }

    private func importSharedImages() {
        let providers = (extensionContext?.inputItems ?? [])
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }

        guard !providers.isEmpty else {
            finish(with: "Không nhận được ảnh sticker.")
            return
        }

        let group = DispatchGroup()
        let tracker = ShareImportTracker()
        providers.forEach { provider in
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                defer { group.leave() }
                guard let data, let image = UIImage(data: data) else {
                    tracker.record(error: error?.localizedDescription ?? "Không đọc được ảnh được chia sẻ.")
                    return
                }
                do {
                    try StickerLibrary.save(image, name: "shared-\(UUID().uuidString)")
                    tracker.recordSuccess()
                } catch {
                    tracker.record(error: error.localizedDescription)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.finish(with: tracker.message)
        }
    }

    private func finish(with message: String) {
        messageLabel.text = message
        doneButton.isHidden = false
    }

    @objc private func done() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

private final class ShareImportTracker {
    private let lock = NSLock()
    private var imported = 0
    private var lastError: String?

    func recordSuccess() {
        lock.lock(); defer { lock.unlock() }
        imported += 1
    }

    func record(error: String) {
        lock.lock(); defer { lock.unlock() }
        lastError = error
    }

    var message: String {
        lock.lock(); defer { lock.unlock() }
        if let lastError { return "Đã thêm \(imported) ảnh. \(lastError)" }
        return "Đã lưu \(imported) sticker vào StickerShelf."
    }
}
