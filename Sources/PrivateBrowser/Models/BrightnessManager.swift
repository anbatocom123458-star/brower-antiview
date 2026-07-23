import SwiftUI
import UIKit
import Combine

/// Quản lý độ sáng màn hình — cho phép điều chỉnh brightness từ trong app,
/// tự lưu giá trị đã chọn và khôi phục khi mở lại app.
final class BrightnessManager: ObservableObject {
    @Published var brightness: CGFloat {
        didSet {
            UIScreen.main.brightness = brightness
            saveBrightness()
        }
    }

    @Published var isAutoBrightness: Bool {
        didSet {
            UserDefaults.standard.set(isAutoBrightness, forKey: Keys.autoBrightness)
        }
    }

    private let minBrightness: CGFloat = 0.02
    private let maxBrightness: CGFloat = 1.0

    private enum Keys {
        static let brightness = "brightness.level"
        static let autoBrightness = "brightness.auto"
    }

    static let shared = BrightnessManager()

    init() {
        let saved = UserDefaults.standard.float(forKey: Keys.brightness)
        let auto = UserDefaults.standard.bool(forKey: Keys.autoBrightness)

        self.isAutoBrightness = auto
        if !auto {
            self.brightness = CGFloat(saved > 0 ? saved : Float(UIScreen.main.brightness))
            UIScreen.main.brightness = self.brightness
        } else {
            self.brightness = UIScreen.main.brightness
        }
    }

    /// Lấy giá trị brightness dưới dạng phần trăm (0-100)
    var brightnessPercent: CGFloat {
        brightness * 100
    }

    /// Đặt lại brightness về mặc định hệ thống
    func resetToDefault() {
        isAutoBrightness = true
        brightness = UIScreen.main.brightness
    }

    /// Tăng brightness một bước
    func increase(by step: CGFloat = 0.1) {
        brightness = min(brightness + step, maxBrightness)
    }

    /// Giảm brightness một bước
    func decrease(by step: CGFloat = 0.1) {
        brightness = max(brightness - step, minBrightness)
    }

    private func saveBrightness() {
        UserDefaults.standard.set(Float(brightness), forKey: Keys.brightness)
    }
}
