<div align="center">

# 🛡️ Private Browser iOS
### *Định nghĩa lại trải nghiệm duyệt web ẩn danh trên iPhone*

**Tác giả:** [Huân Ngô](https://github.com/huanngo) 👨‍💻

![iOS 16+](https://img.shields.io/badge/iOS-16.0%2B-blue?logo=apple)
![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)
![License](https://img.shields.io/badge/License-MIT-orange)
![Xcode Needed](https://img.shields.io/badge/Xcode-Not%20Required-red)
![Version](https://img.shields.io/badge/Version-3.3-brightgreen)

Trình duyệt web cao cấp kết hợp **Hệ thống bảo vệ quyền riêng tư đa lớp**.
*Không cần máy Mac, không cần Xcode, không tốn $99/năm cho Apple Developer.*

---

</div>


## 🧊 Có gì mới trong phiên bản 3.3:
- **Điều chỉnh độ sáng (Brightness Control)**: Trượt để tăng/giảm độ sáng màn hình trực tiếp từ app. Tiết kiệm pin, thoải mái sử dụng trong bóng tối. Tự lưu giá trị đã chọn và khôi phục khi mở lại app.
- **Developer Tools (F12)**: Xem thông tin chi tiết về trang web giống F12 trên máy tính — bao gồm: thông tin trang (URL, title, meta tags), HTML source code, console log lỗi JavaScript, cookies & storage info. Truy cập qua nút wrench trên thanh công cụ hoặc từ Menu.
- **Khôi phục phiên (Session Restore)**: Tự động lưu trạng thái tab và khôi phục khi mở lại app — không mất dữ liệu giữa các phiên. Có thể tắt trong cài đặt.
- **Lưu trạng thái tự động**: Toàn bộ trạng thái tab được lưu khi app chuyển sang nền, đảm bảo dữ liệu không bị mất.
- **Nâng cấp giao diện hiện đại**: Thanh công cụ dưới cùng thêm nút Developer Tools, menu cài đặt thêm phần điều chỉnh độ sáng và các tính năng mới.
- **Cải tiến ổn định**: Xử lý lỗi tốt hơn, tối ưu hiệu năng, mượt mà hơn khi chuyển tab.

## 🧊 Có gì mới trong phiên bản 3.2:
- **Tải xuống File (Download Manager)**: Tải file trực tiếp từ trình duyệt — hỗ trợ mọi loại file. File tải về chế độ riêng tư tự động xóa khi hoàn thành. Truy cập qua nút ↓ trên thanh công cụ.
- **Userscript Manager (giống Tampermonkey)**: Dán code JavaScript tự chạy trên trang web — thay thế cho Chrome Extension trên iOS (giới hạn WKWebView). Hỗ trợ matching URL, chạy lúc Document Start/End, Top frame/All frames.
- **Chế độ Cửa sổ (Window Mode)**: Hiển thị tab dưới dạng các cửa sổ nhỏ gọn — giống trải nghiệm desktop/laptop. Có dock ở dưới cùng với các nút nhanh: Tab mới, Tab riêng tư, Đóng hết, Cài đặt.
- **Lưu trữ dữ liệu bền vững**: Dữ liệu duyệt web ở chế độ thường được lưu trữ khi thoát app — không mất dữ liệu giữa các phiên.
- **Tách tab thường / tab riêng tư**: Quản lý rõ ràng hai loại tab — tab riêng tư hiển thị riêng biệt để tránh nhầm lẫn.
- **Nâng cấp hiệu năng & ổn định**: Tối ưu bộ nhớ, cải thiện xử lý lỗi, mượt mà hơn khi chuyển tab.

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
