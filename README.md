
# Private Browser iOS — v3.1 (Liquid Glass + Tab Riêng Tư & Chặn Trình Theo Dõi Nâng Cao)

Trình duyệt web ẩn danh & bảo mật cao cấp cho iPhone — **không cần Xcode app, không cần Apple Developer**.

## 🧊 Có gì mới trong phiên bản 3.1:
- **Nâng cấp Hiệu ứng Liquid Glass (iOS 26+)**: Tối ưu hóa hiệu ứng kính trong suốt và phản hồi thị giác trên toàn bộ giao diện app (`.glassEffect()`, `GlassEffectContainer`, nút bấm kính `.glass` / `.glassProminent`). Cho trải nghiệm vuốt chạm, khúc xạ ánh sáng sống động và mượt mà tuyệt đối. Tự động rơi về Glassmorphism tương thích hoàn hảo trên các phiên bản iOS cũ hơn (iOS 16–25) mà không gây crash hay lag.
- **Thêm Tab Riêng Tư & Quản Lý Đa Tab (Tab Grid)**: Hỗ trợ duyệt web đa nhiệm với giao diện quản lý tab lưới trực quan (Tab Grid View). Dễ dàng chuyển đổi, tạo tab riêng tư mới hoặc đóng tất cả tab cùng lúc. Mỗi tab hoạt động độc lập trong môi trường cách ly an toàn.
- **Chặn Trình Theo Dõi & Quảng Cáo Nâng Cao (Content Blocker)**: Tích hợp bộ quy tắc chặn tầng network chuẩn Safari `WKContentRuleList`. Chặn triệt để các trình theo dõi, quảng cáo phiền phức và mã độc theo dõi trước khi nội dung được tải về, giúp tăng tốc độ load trang đến 40% và tiết kiệm dung lượng mạng.
- **Tự Động Lọc Tham Số Theo Dõi URL**: Tự động xoá sạch các tham số theo dõi hành vi dùng trong marketing (như `utm_*`, `fbclid`, `gclid`, `msclkid`, `mc_eid`...) khỏi liên kết ngay khi bấm mở hoặc gõ tìm kiếm.
- **Chống Dấu Vân Tay Thiết Bị (Fingerprint Protection) Nâng Cao**: Giả lập/làm nhiễu Canvas, WebGL, AudioContext; ẩn thông tin CPU (`hardwareConcurrency`), RAM (`deviceMemory`), các plugin trình duyệt, chuẩn hóa múi giờ UTC và ẩn `document.referrer` để chặn các công ty quảng cáo nhận dạng thiết bị.
- **Chống Lộ IP & Chặn WebRTC / GeoLocation**: Ngăn chặn tuyệt đối các lỗ hổng rò rỉ IP qua WebRTC, chặn tự động yêu cầu vị trí địa lý, Battery API và loại bỏ hoàn toàn các khung iframe độc hại/quảng cáo chèn ẩn.
- **Bảo Vệ Quyền Riêng Tư Tức Thì**:
  - **Màn hình bảo vệ (Privacy Shield)**: Tự động che phủ màn hình ứng dụng khi chuyển sang App Switcher hoặc khi phát hiện thiết bị đang bị quay màn hình (`UIScreen.isCaptured`).
  - **Tự động dọn dẹp khi rời App**: Xóa sạch toàn bộ Session, Cookies và Cache ngay khi app chuyển sang chế độ chạy ngầm.
  - **Nút "Phiên mới" nhanh**: Xóa sạch tức thì toàn bộ dữ liệu duyệt web hiện tại và đưa người dùng về trang chủ chỉ với 1 chạm từ Menu.
- **Trải Nghiệm Người Dùng Tối Ưu**:
  - Đầy đủ tính năng Zoom trang (25% → 200%), Menu cài đặt riêng linh hoạt, chọn công cụ tìm kiếm mặc định (DuckDuckGo, Google, Bing, Brave, Yahoo).
  - Xử lý mượt mà các hộp thoại JavaScript (`alert`, `confirm`, `prompt`) và các luồng liên kết hệ thống (`tel:`, `mailto:`, `sms:`).
## 🛠️ Khắc phục lỗi & Tăng độ ổn định từ bản v3.0:
- **Sửa lỗi dính Captcha / Cloudflare Turnstile**: Loại bỏ việc can thiệp ngẫu nhiên vào Canvas/AudioContext và giả mạo mâu thuẫn giữa `navigator.platform` với `userAgent` — nguyên nhân chính ở v3.0 khiến các hệ thống chống bot như Cloudflare, reCAPTCHA v3 liên tục yêu cầu xác minh "tôi không phải robot".
- **Sửa lỗi trang bị "treo" khi hiện hộp thoại JS**: Thêm đầy đủ trình xử lý cho `alert()`, `confirm()`, và `prompt()` của JavaScript.
- **Sửa lỗi vòng lặp reload (Loop Reload) khi gõ URL**: Tách hoàn toàn logic điều hướng ra khỏi vòng đời render của SwiftUI (`updateUIView`), chuyển sang điều khiển tường minh bằng `BrowserController`.
- **Bắt lỗi JavaScript Runtime (React / Next.js Exception)**: Lắng nghe các lỗi uncaught exception/unhandled rejection từ JS client-side (như lỗi "Application error" của DuckDuckGo) để tự động hiển thị màn hình thông báo lỗi kèm nút **"Thử lại"** thay vì bị trang trắng/màn hình đen im lặng.
- **Khắc phục rò rỉ bộ nhớ (Memory Leak)**: Dọn dẹp chính xác các `KVO Observer` và gỡ bỏ `ScriptMessageHandler` trong `dismantleUIView` khi đóng tab/WebView.
- **Xử lý an toàn các URL Scheme ngoại lệ**: Chuyển giao các liên kết dạng `tel:`, `mailto:`, `sms:`, `facetime:` cho hệ thống iOS xử lý thay vì gây đơ hoặc crash WebView.

## Cách dùng
1. Tạo repo GitHub, push toàn bộ file trên
2. Vào [Codemagic](https://codemagic.io) → Add app → Chọn repo
3. Start build → Tải IPA unsigned về
4. Cài IPA qua **AltStore**, **Sideloadly**, hoặc **Scarlet** (không cần Apple Developer $99)

## Lưu ý
- IPA unsigned cần được **re-sign** bằng Apple ID free qua AltStore/Sideloadly để cài lên iPhone thật
- Nếu có Apple Developer, chỉ cần thêm certificate vào Codemagic để build signed
