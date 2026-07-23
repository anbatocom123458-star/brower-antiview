import Foundation

/// Danh sách tập trung tất cả các key UserDefaults/AppStorage dùng trong app.
/// Gom về một nơi để tránh gõ sai chuỗi (magic string) và dễ bảo trì — tăng ổn định.
enum SettingsKey {
    static let defaultHTTP = "settings.defaultHTTP"
    static let searchEngine = "settings.searchEngineRaw"
    static let blockWebRTC = "settings.blockWebRTC"
    static let blockIframe = "settings.blockIframe"
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let confirmClearData = "settings.confirmClearData"
    static let desktopMode = "settings.desktopMode"
    static let blockAds = "settings.blockAds"
    static let autoClearOnBackground = "settings.autoClearOnBackground"
    static let windowMode = "settings.windowMode"
    static let autoDeletePrivateDownloads = "settings.autoDeletePrivateDownloads"
    static let userscriptsEnabled = "settings.userscriptsEnabled"

    // MARK: - New Keys (v3.3)
    static let restoreSession = "settings.restoreSession"
    static let developerToolsEnabled = "settings.developerToolsEnabled"
    static let brightnessAuto = "settings.brightnessAuto"
}
