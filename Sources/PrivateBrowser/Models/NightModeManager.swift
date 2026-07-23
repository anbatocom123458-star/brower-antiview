import SwiftUI

/// Bộ lọc ánh sáng xanh ban đêm — overlay vàng nhạt giảm mỏi mắt.
/// v4.1: Night mode với intensity adjustible.
final class NightModeManager: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var intensity: Double = 0.15

    static let shared = NightModeManager()

    private enum Keys {
        static let enabled = "nightMode.enabled"
        static let intensity = "nightMode.intensity"
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        intensity = UserDefaults.standard.double(forKey: Keys.intensity)
        if intensity == 0 { intensity = 0.15 }
    }

    func toggle() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: Keys.enabled)
    }

    func setIntensity(_ value: Double) {
        intensity = value
        UserDefaults.standard.set(value, forKey: Keys.intensity)
    }

    var overlayColor: Color {
        Color.orange.opacity(intensity)
    }
}
