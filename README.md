# StickerShelf for RootHide

Bản thử nghiệm cho iPhone X/iOS 16.7.x. StickerShelf lưu ảnh sticker cục bộ rồi hiển thị chúng trong bộ sticker của iOS, có thể mở từ bàn phím Emoji. Đây là thư viện riêng, không bật lại giao diện Live Stickers gốc của iOS 17.

## Cách dùng

1. Cài `StickerShelf.deb` bằng Sileo trên thiết bị RootHide.
2. Mở ứng dụng **StickerShelf** một lần.
3. Chọn **Thêm từ Ảnh** hoặc **Thêm PNG/JPG từ Tệp**. Ảnh PNG có nền trong suốt sẽ giữ được hình sticker; ứng dụng không tự tách chủ thể khỏi ảnh. Nếu Messenger có nút **Chia sẻ** cho tin nhắn sticker, bạn cũng có thể gửi nó thẳng đến StickerShelf.
4. Mở bàn phím Emoji trong Messenger, mở khu vực sticker, rồi chọn bộ **My Stickers**.
5. Nhấn giữ một sticker trong ứng dụng StickerShelf để xóa nó khỏi thư viện.

Ảnh được giữ cục bộ tại `/var/mobile/Library/StickerShelf`; ứng dụng không tải ảnh lên mạng. Sticker phải nhỏ hơn 500 KB để tương thích với giao diện sticker của iOS. Khi chọn sticker trong ứng dụng khác, cách ứng dụng đó nhận hình còn tùy Messenger và iOS.

## Build từ Windows bằng GitHub Actions

Workflow `.github/workflows/build-stickershelf.yml` dùng máy macOS của GitHub để chạy Xcode, nên không cần cài Ubuntu hoặc Xcode trên laptop. Đưa nội dung thư mục dự án này vào một repository GitHub, rồi chạy **Actions → Build StickerShelf for RootHide → Run workflow**. Tải artifact `StickerShelf-deb` sau khi workflow hoàn tất.

## Ghi chú

- Đây là bản thử nghiệm, chưa được cài hoặc kiểm tra trên iPhone X vật lý.
- StickerShelf dùng Messages sticker extension của iOS để đăng ký một bộ sticker riêng. Vị trí hiển thị có thể khác với ngăn Live Stickers trong iOS 17+.
- Ứng dụng có tiện ích nhập ảnh từ bảng Chia sẻ; khả năng chia sẻ sticker cụ thể tùy Messenger. Nó không tự tách chủ thể khỏi ảnh như trong video.
- Package này độc lập với `LiveTextEnabler`.
