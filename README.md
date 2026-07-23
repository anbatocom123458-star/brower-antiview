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


## 🧊 Phiên bản 3.3 — Floating Window & Virtual Cursor

### Con trỏ ảo toàn cục (Global Virtual Cursor)
- **Single cursor across entire screen** — một con trỏ duy nhất di chuyển tự do trên toàn màn hình, không bị giới hạn trong bất kỳ cửa sổ nào
- Trackpad-style: vuốt = di chuyển, chạm = click, giữ + kéo = drag
- Cursor tự động chọn cửa sổ đang chứa vị trí click
- Hiệu ứng ripple khi click, drag trail particles

### Cửa sổ nổi nâng cao (Floating Window)
- Kéo di chuyển mượt mà với snap-to-edge
- Resize từ mọi góc/cạnh cửa sổ
- Tỉ lệ khung hình tùy chọn (16:9, 4:3, 1:1, ...)
- Bubble/PiP mode — thu nhỏ thành bong bóng nổi
- Reader Mode với AI tóm tắt bài viết
- Browser toolbar tích hợp (URL, navigation, reload)

### Dock & Đa cửa sổ
- Glassmorphism dock ở dưới cùng
- Multi-window tiling (2 hoặc 4 cửa sổ lưới)
- Virtual cursor toggle từ dock
- Tab management trực quan

---

## 🧊 Phiên bản 4.1 — 20+ Tính năng mới

### Tính năng mới (20+)
| # | Tính năng | Mô tả |
|---|-----------|-------|
| 1 | **HapticManager** | Centralized haptic feedback — xóa 10+ hàm trùng lặp |
| 2 | **BookmarkManager** | Lưu bookmark + tab đã đóng (20 tab bộ nhớ) |
| 3 | **FindInPage** | Tìm text trong trang, prev/next, đếm kết quả |
| 4 | **NightMode** | Bộ lọc ánh sáng xanh ban đêm, điều chỉnh cường độ |
| 5 | **FontSizeManager** | Tăng/giảm cỡ chữ nhanh +/- (60%-200%) |
| 6 | **PrivacyGrade** | Đánh giá A-F mức riêng tư real-time trên URL bar |
| 7 | **SitePermissionManager** | Quản lý quyền camera/mic/location theo từng trang |
| 8 | **StorageMonitor** | Theo dõi dung lượng dữ liệu tiết kiệm |
| 9 | **ClipboardGuard** | Tự xóa URL sao chép sau 30 giây |
| 10 | **QuickSettingsPanel** | Truy cập nhanh toggle từ toolbar |
| 11 | **BookmarkListView** | Danh sách bookmark với search |
| 12 | **FindInPageView** | UI Find on Page với result counter |
| 13 | **NightModeOverlay** | Full-screen blue light filter |
| 14 | **PrivacyGradeBadge** | Badge màu A-F trên URL bar |
| 15 | **SiteInfoView** | Thông tin trang (tap lock icon) |
| 16 | **StorageStatsView** | Hiển thị thống kê lưu trữ |
| 17 | **HTTPS-Only Mode** | Tự chuyển HTTP → HTTPS |
| 18 | **Do Not Track Header** | Gửi yêu cầu DNT đến mọi trang |
| 19 | **Clipboard Guard** | Bảo vệ clipboard tự động |
| 20 | **Privacy Grade Toggle** | Bật/tắt hiển thị A-F grade |

### Sửa lỗi & Ổn định
- Fixed `MARKETING_VERSION` trong project.yml
- Fixed `print()` trong production code (`#if DEBUG`)
- Fixed `PrivacyReport` thread safety (`DispatchQueue.main.async`)
- Fixed deprecated `UIScreen.main.bounds` → `UIWindowScene` bounds
- Fixed `SitePermissionManager` KVC usage

---

## 🧊 Các phiên bản trước

### Phiên bản 3.2
- **Tải xuống File (Download Manager)**: Tải file trực tiếp từ trình duyệt — hỗ trợ mọi loại file. File tải về chế độ riêng tư tự động xóa khi hoàn thành.
- **Userscript Manager (giống Tampermonkey)**: Dán code JavaScript tự chạy trên trang web — thay thế cho Chrome Extension trên iOS.
- **Chế độ Cửa sổ (Window Mode)**: Hiển thị tab dưới dạng các cửa sổ nhỏ gọn — giống trải nghiệm desktop/laptop.

### Phiên bản 3.1
- **Liquid Glass (iOS 26+)**: Hiệu ứng kính trong suốt trên toàn bộ giao diện.
- **Tab Riêng Tư & Tab Grid**: Quản lý tab lưới trực quan, tab riêng tư cách ly an toàn.
- **Content Blocker**: Chặn trình theo dõi & quảng cáo ở tầng network chuẩn Safari.
- **Auto-strip Tracking URL**: Tự động xoá `utm_*`, `fbclid`, `gclid` khỏi URL.
- **Fingerprint Protection**: Giả lập Canvas, WebGL, AudioContext; ẩn CPU, RAM, plugins.
- **Anti-IP Leak**: Chặn WebRTC, GeoLocation, Battery API.
- **Privacy Shield**: Tự che màn hình khi App Switcher hoặc screen recording.

---

## 🛠️ Khắc phục lỗi từ bản v3.0
- **Sửa lỗi Captcha/Cloudflare Turnstile**: Loại bỏ can thiệp Canvas/AudioContext mâu thuẫn.
- **Sửa lỗi treo khi hiện hộp thoại JS**: Xử lý đầy đủ `alert()`, `confirm()`, `prompt()`.
- **Sửa lỗi vòng lặp reload**: Tách logic điều hướng khỏi SwiftUI render loop.
- **Bắt lỗi JavaScript Runtime**: Hiển thị màn hình lỗi thay vì trắng màn hình.
- **Khắc phục rò rỉ bộ nhớ**: Dọn dẹp KVO Observer và ScriptMessageHandler chính xác.

---

## Cách dùng
1. Tạo repo GitHub, push toàn bộ file trên
2. Vào [Codemagic](https://codemagic.io) → Add app → Chọn repo
3. Start build → Tải IPA unsigned về
4. Cài IPA qua **AltStore**, **Sideloadly**, hoặc **Scarlet** (không cần Apple Developer $99)

## Lưu ý
- IPA unsigned cần được **re-sign** bằng Apple ID free qua AltStore/Sideloadly để cài lên iPhone thật
- Nếu có Apple Developer, chỉ cần thêm certificate vào Codemagic để build signed
