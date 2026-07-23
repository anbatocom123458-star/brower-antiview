# Private Browser iOS — v3.0 (Liquid Glass + Bảo vệ nâng cao)

Trình duyệt web kín cho iPhone — **không cần Xcode app, không cần Apple Developer**.

## 🧊 Mới trong v3.0: Liquid Glass & ẩn mình nâng cao
- **Hiệu ứng Liquid Glass (iOS 26+)**: thanh địa chỉ, thanh công cụ, panel zoom, hộp báo lỗi giờ dùng `.glassEffect()` / `GlassEffectContainer` thật của hệ thống — kính trong, khúc xạ ánh sáng, phản hồi chạm mượt. Trên iOS 16–25 tự rơi về hiệu ứng glassmorphism cũ, không đổi hành vi, không crash.
- **Nút bấm kính (`.glass` / `.glassProminent`)**: các nút hành động chính ("Thử lại", "Đặt lại zoom"...) dùng button style kính chuẩn của iOS 26, có hiệu ứng nhún/sáng khi nhấn.
- **Chặn quảng cáo & trình theo dõi ở tầng network**: dùng `WKContentRuleList` (định dạng Content Blocker của Safari) — chặn trước khi tải về, nhẹ hơn nhiều so với chỉ lọc bằng JavaScript.
- **Tự dọn tham số theo dõi trong URL**: xoá `utm_*`, `fbclid`, `gclid`, `msclkid`... khỏi mọi liên kết trước khi mở, cả khi gõ URL và khi bấm link trong trang.
- **Chống dấu vân tay nâng cao**: thêm chuẩn hoá múi giờ (UTC), `hardwareConcurrency`, `deviceMemory`, ẩn `navigator.plugins`, làm nhiễu AudioContext (chống audio fingerprinting), ẩn `document.referrer`.
- **Tự động xoá dữ liệu khi rời app** (tuỳ chọn): bật trong Menu để mọi cookie/cache bị xoá ngay khi chuyển sang app khác.
- **Tự ẩn khi bị ghi màn hình**: phát hiện `UIScreen.isCaptured` (quay màn hình) và tự động che nội dung, không chỉ khi vào App Switcher.
- **"Phiên mới"**: một nút trong Menu để xoá sạch dữ liệu + về trang chủ ngay lập tức, không cần vào từng bước.

## 🆕 Có gì mới trong bản cải tiến trước (v2.0)
- **Kiến trúc lại toàn bộ**: tách rõ Models / Views / WebView / Extensions, dễ bảo trì, dễ mở rộng.
- **Menu riêng đầy đủ**: màn hình cài đặt riêng (không còn dropdown nhỏ) — chọn công cụ tìm kiếm, bật/tắt từng lớp bảo vệ, chế độ máy tính, haptics, xác nhận trước khi xoá dữ liệu.
- **Phần Giới thiệu chi tiết**: icon app, mô tả, lưới tính năng minh hoạ bằng icon, số phiên bản đọc trực tiếp từ bundle.
- **App Icon riêng**: bộ icon đầy đủ kích thước (20pt → 1024pt) theo chủ đề shield/incognito, đã nhúng vào Assets.xcassets.
- **Tăng ổn định**:
  - Xử lý đầy đủ JS `alert` / `confirm` / `prompt` — nhiều trang trước đây có thể bị "treo" vì WKWebView không phản hồi các hộp thoại này.
  - Bỏ cách so sánh URL ở mỗi lần render (nguồn gây loop reload khi đang gõ) — thay bằng `BrowserController` điều khiển điều hướng tường minh.
  - Hiển thị màn hình lỗi thân thiện khi mất mạng / DNS lỗi / SSL lỗi, có nút "Thử lại".
  - Dọn dẹp KVO observer đúng cách (deinit) — tránh rò nhớ khi đóng WebView.
  - Chặn an toàn các scheme lạ (`tel:`, `mailto:`, `sms:`...) bằng cách chuyển cho hệ thống xử lý thay vì crash.
  - Zoom chỉ inject JavaScript khi giá trị thực sự đổi — mượt hơn, đỡ tốn pin.
  - Sửa lỗi cấu trúc project (đường dẫn sai hoa/thường, tên thư mục `Assets.xcassets` bị gõ nhầm) từng có thể khiến build thất bại trên máy phân biệt hoa/thường.
- **Riêng tư nâng cao**: màn hình che (Privacy Shield) tự động phủ nội dung khi app chuyển sang nền, tránh lộ ảnh xem trước trong App Switcher.
- **Tối ưu**: cho phép bật/tắt riêng từng lớp chống rò IP / chống fingerprint / chặn iframe, để tương thích tốt hơn với các trang nhạy với việc bị chặn quá tay.

## Tính năng nổi bật
- **Private Mode tuyệt đối**: `nonPersistent`, không cache, không cookie, không lịch sử
- **Chống lộ IP**: Chặn WebRTC, GeoLocation, Battery API, Canvas/WebGL Fingerprint
- **Chặn iframe**: Xoá sạch iframe trên mọi trang web, kể cả chèn động
- **Menu riêng**: cấu hình toàn bộ hành vi bảo mật & trải nghiệm ở một nơi
- **Giới thiệu chi tiết**: xem đầy đủ tính năng và phiên bản app
- **Zoom linh hoạt**: 25% → 200% với slider trực quan
- **UI/UX đẹp**: Dark mode, glassmorphism, gradient, animation mượt
- **Build tự động**: Push GitHub → Codemagic build IPA unsigned

## Cách dùng
1. Tạo repo GitHub, push toàn bộ file trên
2. Vào [Codemagic](https://codemagic.io) → Add app → Chọn repo
3. Start build → Tải IPA unsigned về
4. Cài IPA qua **AltStore**, **Sideloadly**, hoặc **Scarlet** (không cần Apple Developer $99)

## Lưu ý
- IPA unsigned cần được **re-sign** bằng Apple ID free qua AltStore/Sideloadly để cài lên iPhone thật
- Nếu có Apple Developer, chỉ cần thêm certificate vào Codemagic để build signed
