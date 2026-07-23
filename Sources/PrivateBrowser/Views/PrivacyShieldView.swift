import SwiftUI

/// Lý do lớp phủ riêng tư đang hiển thị — dùng để đổi icon/thông báo phù hợp.
enum PrivacyShieldReason {
    case background
    case screenRecording
}

/// Màn hình che phủ toàn bộ nội dung khi app chuyển sang nền (background) hoặc khi
/// phát hiện đang bị ghi màn hình/chụp màn hình — tránh lộ nội dung đang duyệt riêng tư
/// qua ảnh xem trước (App Switcher) hoặc qua ghi hình. Đây là lớp bảo vệ "ẩn mình" quan trọng.
struct PrivacyShieldView: View {
    var reason: PrivacyShieldReason = .background

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: reason == .screenRecording ? "record.circle.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        reason == .screenRecording
                            ? LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: AppTheme.accentGradient, startPoint: .top, endPoint: .bottom)
                    )
                Text("Private Browser")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Text(reason == .screenRecording ? "Đã phát hiện ghi màn hình — nội dung đã được ẩn" : "Nội dung được ẩn để bảo vệ riêng tư")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .transition(.opacity)
    }
}
