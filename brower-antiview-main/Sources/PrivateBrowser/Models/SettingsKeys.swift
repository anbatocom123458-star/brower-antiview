import Foundation

/// Danh sách tập trung tất cả các key UserDefaults/AppStorage dùng trong app.
/// Gom về một nơi để tránh gõ sai chuỗi (magic string) và dễ bảo trì — tăng ổn định.
enum SettingsKey {
    static let defaultHTTP = "settings.defaultHTTP"
    static let searchEngine = "settings.searchEngineRaw"
    static let blockWebRTC = "settings.blockWebRTC"
    static let blockIframe = "settings.blockIframe"
    static let blockFingerprint = "settings.blockFingerprint"
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let confirmClearData = "settings.confirmClearData"
    static let desktopMode = "settings.desktopMode"
}
