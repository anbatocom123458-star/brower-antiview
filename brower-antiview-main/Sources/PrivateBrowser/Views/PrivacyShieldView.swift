import SwiftUI

/// Màn hình che phủ toàn bộ nội dung khi app chuyển sang nền (background) hoặc bị
/// khoá — tránh ảnh xem trước (App Switcher) hoặc người khác nhìn thấy nội dung
/// đang duyệt riêng tư. Đây là điểm cộng bảo mật/ổn định phù hợp với "Private Browser".
struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: AppTheme.accentGradient, startPoint: .top, endPoint: .bottom)
                    )
                Text("Private Browser")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Text("Nội dung được ẩn để bảo vệ riêng tư")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .transition(.opacity)
    }
}
