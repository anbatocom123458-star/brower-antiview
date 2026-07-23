import UIKit

/// Trung tâm quản lý haptic feedback — thay thế 10+ bản sao chép `private func haptic()` phân tán
/// trong các View. Giảm ~120 dòng code trùng lặp, tăng nhất quán và dễ bảo trì.
enum HapticManager {
    private static var enabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.hapticsEnabled)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
