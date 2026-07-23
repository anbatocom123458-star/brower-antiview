import SwiftUI

/// Lớp phủ hiển thị khi tải trang lỗi (mất mạng, DNS lỗi, SSL lỗi...) thay vì để
/// WKWebView hiện trang trắng khó hiểu — tăng ổn định/trải nghiệm khi mất kết nối.
struct ErrorOverlayView: View {
    let message: String
    var onRetry: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.orange)

            Text("Không thể tải trang")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Đóng")
                }
                .adaptiveGlassButton()

                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Thử lại")
                    }
                }
                .adaptiveGlassButton(prominent: true, tint: .cyan)
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.4), radius: 20)
        .transition(.scale.combined(with: .opacity))
    }
}
