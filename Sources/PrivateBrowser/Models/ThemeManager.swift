import SwiftUI

/// Quản lý theme/giao diện — Dark/Light/Auto và accent color.
final class ThemeManager: ObservableObject {
    @Published var themeMode: ThemeMode = .dark {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: Keys.themeMode) }
    }
    @Published var accentColor: AccentColor = .cyan {
        didSet { UserDefaults.standard.set(accentColor.rawValue, forKey: Keys.accentColor) }
    }

    private enum Keys {
        static let themeMode = "theme.mode"
        static let accentColor = "theme.accentColor"
    }

    static let shared = ThemeManager()

    init() {
        let modeRaw = UserDefaults.standard.string(forKey: Keys.themeMode) ?? ThemeMode.dark.rawValue
        self.themeMode = ThemeMode(rawValue: modeRaw) ?? .dark
        let colorRaw = UserDefaults.standard.string(forKey: Keys.accentColor) ?? AccentColor.cyan.rawValue
        self.accentColor = AccentColor(rawValue: colorRaw) ?? .cyan
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .dark: return .dark
        case .light: return .light
        case .auto: return nil
        }
    }

    var uiColor: UIColor {
        accentColor.uiColor
    }
}

enum ThemeMode: String, CaseIterable, Identifiable {
    case dark
    case light
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Tối"
        case .light: return "Sáng"
        case .auto: return "Tự động"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}

enum AccentColor: String, CaseIterable, Identifiable {
    case cyan, blue, green, purple, orange, red

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyan: return "Xanh ngọc"
        case .blue: return "Xanh dương"
        case .green: return "Xanh lá"
        case .purple: return "Tím"
        case .orange: return "Cam"
        case .red: return "Đỏ"
        }
    }

    var color: Color {
        switch self {
        case .cyan: return .cyan
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }

    var uiColor: UIColor {
        switch self {
        case .cyan: return .cyan
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }
}
