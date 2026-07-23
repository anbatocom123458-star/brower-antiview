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

    // MARK: - v3.3
    static let restoreSession = "settings.restoreSession"
    static let developerToolsEnabled = "settings.developerToolsEnabled"
    static let brightnessAuto = "settings.brightnessAuto"

    // MARK: - v3.4 Floating Window
    static let virtualCursorEnabled = "settings.virtualCursorEnabled"
    static let aspectRatioLocked = "settings.aspectRatioLocked"
    static let aspectRatioPreset = "settings.aspectRatioPreset"

    // MARK: - v3.4 Biometric Lock
    static let biometricLockPrivateTabs = "settings.biometricLockPrivateTabs"

    // MARK: - v4.1
    static let httpsOnlyMode = "settings.httpsOnlyMode"
    static let nightMode = "settings.nightMode"
    static let cookieClearInterval = "settings.cookieClearInterval"
    static let doNotTrackHeader = "settings.doNotTrackHeader"
    static let showPrivacyGrade = "settings.showPrivacyGrade"
    static let clipboardGuard = "settings.clipboardGuard"
}
