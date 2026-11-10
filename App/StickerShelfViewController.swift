import PhotosUI
import UIKit
import UniformTypeIdentifiers

final class StickerShelfViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    private var files: [URL] = []
    private var collectionView: UICollectionView!
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "StickerShelf"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        buildInterface()
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    private func buildInterface() {
        let description = UILabel()
        description.text = "Lưu sticker một lần, rồi chọn lại trong bàn phím Emoji. Dùng ảnh PNG có nền trong suốt để giữ hình sticker."
        description.numberOfLines = 0
        description.font = .preferredFont(forTextStyle: .subheadline)
        description.textColor = .secondaryLabel

        let photosButton = makeButton(title: "Thêm từ Ảnh", symbol: "photo")
        photosButton.addTarget(self, action: #selector(choosePhotos), for: .touchUpInside)
        let filesButton = makeButton(title: "Thêm PNG/JPG từ Tệp", symbol: "folder")
        filesButton.addTarget(self, action: #selector(chooseFiles), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: StickerCell.reuseIdentifier)

        let buttons = UIStackView(arrangedSubviews: [photosButton, filesButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 10

        let header = UIStackView(arrangedSubviews: [description, buttons, statusLabel])
        header.axis = .vertical
        header.spacing = 14
        header.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeButton(title: String, symbol: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 6
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }

    private func refresh() {
        try? StickerLibrary.prepare()
        files = StickerLibrary.files()
        statusLabel.text = files.isEmpty
            ? "Chưa có sticker. Chọn ảnh ở trên để bắt đầu."
            : "Đã lưu \(files.count) sticker. Nhấn giữ một hình để xóa."
        collectionView?.reloadData()
    }

    @objc private func choosePhotos() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 0
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func chooseFiles() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.png, .jpeg, .heic], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        let tracker = ImportTracker()
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                defer { group.leave() }
                guard let image = object as? UIImage else {
                    tracker.record(error: error?.localizedDescription ?? "Không đọc được một ảnh đã chọn.")
                    return
                }
                do {
                    try StickerLibrary.save(image, name: "photo-\(UUID().uuidString)")
                    tracker.recordSuccess()
                } catch {
                    tracker.record(error: error.localizedDescription)
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.refresh()
            if let message = tracker.summary { self?.showMessage(message) }
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var imported = 0
        var lastError: String?
        for url in urls {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            guard let image = UIImage(contentsOfFile: url.path) else {
                lastError = "Không đọc được \(url.lastPathComponent)."
                continue
            }
            do {
                try StickerLibrary.save(image, name: "file-\(UUID().uuidString)")
                imported += 1
            } catch {
                lastError = error.localizedDescription
            }
        }
        refresh()
        if let lastError { showMessage("Đã thêm \(imported). \(lastError)") }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "StickerShelf", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.reuseIdentifier, for: indexPath) as! StickerCell
        cell.imageView.image = UIImage(contentsOfFile: files[indexPath.item].path)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 32 - 24) / 3
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let url = files[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIAction(title: "Xóa sticker", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                try? StickerLibrary.remove(url)
                self?.refresh()
            }
        }
    }
}

private final class ImportTracker {
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

    var summary: String? {
        lock.lock(); defer { lock.unlock() }
        guard let lastError else { return nil }
        return "Đã thêm \(imported). \(lastError)"
    }
}

private final class StickerCell: UICollectionViewCell {
    static let reuseIdentifier = "StickerCell"
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
