import SwiftUI

extension Color {
    /// Khởi tạo Color từ chuỗi hex "RRGGBB". Trả về màu xám nếu chuỗi không hợp lệ
    /// (thay vì crash) — tăng độ ổn định khi truyền hex sai định dạng.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&rgb) else {
            self = Color.gray
            return
        }
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

/// Bảng màu chủ đề dùng chung toàn app — tránh lặp lại hex rời rạc ở nhiều file.
enum AppTheme {
    static let backgroundTop = Color(hex: "0A0A1A")
    static let backgroundBottom = Color(hex: "12122B")
    static let panel = Color(hex: "1A1A2E")
    static let accentGradient: [Color] = [.cyan, .blue, .purple]
    static let accent = Color.cyan
    static let privatePurple = Color.purple
    static let dangerRed = Color.red
    static let successGreen = Color.green
    static let warningOrange = Color.orange
    static let mutedGray = Color.white.opacity(0.4)
    static let subtleWhite = Color.white.opacity(0.08)
    static let divider = Color.white.opacity(0.1)

    static func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.25))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.clear], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 0.5)
        }
    }
}
