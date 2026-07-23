import SwiftUI

@main
struct PrivateBrowserApp: App {
    init() {
        registerDefaultSettingsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }

    /// Đăng ký giá trị mặc định cho các cờ bảo vệ quyền riêng tư ngay khi app khởi động,
    /// để lần chạy đầu tiên các bộ lọc (WebRTC, iframe, quảng cáo...) đã ở trạng thái
    /// bật sẵn — tránh trường hợp UserDefaults trả về `false` mặc định trước khi
    private func registerDefaultSettingsIfNeeded() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.blockWebRTC: true,
            SettingsKey.blockIframe: true,
            SettingsKey.hapticsEnabled: true,
            SettingsKey.confirmClearData: true,
            SettingsKey.defaultHTTP: false,
            SettingsKey.desktopMode: false,
            SettingsKey.searchEngine: SearchEngine.duckduckgo.rawValue,
            SettingsKey.restoreSession: true,
            SettingsKey.developerToolsEnabled: true
        ])
    }
}
