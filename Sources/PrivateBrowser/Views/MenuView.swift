import SwiftUI

/// Menu riêng của app — thay cho dropdown Menu nhỏ trước đây bằng một màn hình
/// cài đặt đầy đủ, có icon, chia nhóm rõ ràng: Trình duyệt, Bảo mật, Trải nghiệm, Dữ liệu, Thông tin.
struct MenuView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.searchEngine) private var searchEngineRaw = SearchEngine.duckduckgo.rawValue
    @AppStorage(SettingsKey.defaultHTTP) private var defaultHTTP = false
    @AppStorage(SettingsKey.desktopMode) private var desktopMode = false
    @AppStorage(SettingsKey.blockWebRTC) private var blockWebRTC = true
    @AppStorage(SettingsKey.blockIframe) private var blockIframe = true
    @AppStorage(SettingsKey.blockAds) private var blockAds = true
    @AppStorage(SettingsKey.autoClearOnBackground) private var autoClearOnBackground = false
    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKey.confirmClearData) private var confirmClearData = true
    @AppStorage(SettingsKey.windowMode) private var windowMode = false
    @AppStorage(SettingsKey.userscriptsEnabled) private var userscriptsEnabled = true
    @AppStorage(SettingsKey.restoreSession) private var restoreSession = true
    @AppStorage(SettingsKey.developerToolsEnabled) private var developerToolsEnabled = true

    @ObservedObject private var brightnessManager = BrightnessManager.shared

    @State private var showClearConfirm = false
    @State private var showClearedToast = false
    @State private var showNewSessionToast = false

    var onShowAbout: () -> Void
    var onClearData: () -> Void
    var onNewSession: () -> Void
    var onOpenPrivateTab: () -> Void
    var onOpenUserscriptEditor: (() -> Void)?
    var onToggleWindowMode: (() -> Void)?
    var onOpenDeveloperTools: (() -> Void)?
    var onToggleFloatingMode: (() -> Void)?
    var currentWindowMode: Bool = false
    var currentFloatingMode: Bool = false

    private var searchEngine: SearchEngine {
        SearchEngine(rawValue: searchEngineRaw) ?? .duckduckgo
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                List {
                    Section {
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onOpenPrivateTab()
                            }
                        }) {
                            SettingRow(icon: "eyeglasses", tint: .purple, title: "Mở tab Riêng tư", subtitle: "Không lưu lịch sử, cookie, cache — tự xoá khi đóng tab")
                        }
                    }
                    .listRowBackground(Color.purple.opacity(0.12))

                    Section {
                        Picker(selection: $searchEngineRaw) {
                            ForEach(SearchEngine.allCases) { engine in
                                Label(engine.displayName, systemImage: engine.icon).tag(engine.rawValue)
                            }
                        } label: {
                            SettingRow(icon: "text.magnifyingglass", tint: .cyan, title: "Công cụ tìm kiếm")
                        }

                        Toggle(isOn: $defaultHTTP) {
                            SettingRow(icon: "lock.open", tint: .orange, title: "Dùng HTTP mặc định", subtitle: "Tự thêm http:// thay vì https:// khi gõ tên miền")
                        }

                        Toggle(isOn: $desktopMode) {
                            SettingRow(icon: "desktopcomputer", tint: .blue, title: "Chế độ máy tính", subtitle: "Hiển thị trang web như trên desktop")
                        }
                    } header: {
                        Text("Trình duyệt")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        Toggle(isOn: $blockWebRTC) {
                            SettingRow(icon: "wifi.slash", tint: .green, title: "Chặn rò IP (WebRTC)", subtitle: "Chặn WebRTC, vị trí GPS, Battery API")
                        }
                        Toggle(isOn: $blockIframe) {
                            SettingRow(icon: "rectangle.slash", tint: .pink, title: "Chặn iframe", subtitle: "Tự xoá iframe ẩn/theo dõi trên trang")
                        }
                        Toggle(isOn: $blockAds) {
                            SettingRow(icon: "shield.slash", tint: .cyan, title: "Chặn quảng cáo & trình theo dõi", subtitle: "Chặn ở tầng network — nhẹ và hiệu quả hơn JS")
                        }
                    } header: {
                        Text("Bảo mật & Riêng tư")
                    } footer: {
                        Text("URL cũng được tự động dọn sạch tham số theo dõi (utm_*, fbclid, gclid...) khi mở trang.")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        Toggle(isOn: $hapticsEnabled) {
                            SettingRow(icon: "hand.tap", tint: .yellow, title: "Phản hồi rung (Haptics)")
                        }
                        Toggle(isOn: $confirmClearData) {
                            SettingRow(icon: "checkmark.shield", tint: .mint, title: "Xác nhận trước khi xoá dữ liệu")
                        }
                        Toggle(isOn: $autoClearOnBackground) {
                            SettingRow(icon: "eye.slash", tint: .indigo, title: "Tự động xoá dữ liệu khi rời app", subtitle: "Xoá ngay khi chuyển sang app khác/vào nền — ẩn mình tối đa")
                        }
                        Toggle(isOn: $restoreSession) {
                            SettingRow(icon: "arrow.clockwise", tint: .teal, title: "Khôi phục phiên trước", subtitle: "Tự mở lại tab đã dùng khi khởi động app")
                        }
                    } header: {
                        Text("Trải nghiệm")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SettingRow(icon: "sun.max.fill", tint: .yellow, title: "Độ sáng màn hình")
                                Spacer()
                                Text("\(Int(brightnessManager.brightnessPercent))%")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "sun.min.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow.opacity(0.5))
                                Slider(value: Binding(
                                    get: { brightnessManager.brightness },
                                    set: { brightnessManager.brightness = $0 }
                                ), in: 0.02...1.0)
                                .tint(.yellow)
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow.opacity(0.8))
                            }
                            Toggle(isOn: $brightnessManager.isAutoBrightness) {
                                SettingRow(icon: "autostartstop", tint: .blue, title: "Tự động điều chỉnh", subtitle: "Hệ thống quản lý độ sáng")
                            }
                        }
                    } header: {
                        Text("Độ sáng")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        Toggle(isOn: $userscriptsEnabled) {
                            SettingRow(icon: "chevron.left.forwardslash.chevron.right", tint: .green, title: "Userscript Manager", subtitle: "Dán code JS tự chạy trên trang — giống Tampermonkey")
                        }
                        if userscriptsEnabled {
                            Button(action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    onOpenUserscriptEditor?()
                                }
                            }) {
                                SettingRow(icon: "doc.text", tint: .cyan, title: "Quản lý Userscripts", subtitle: "Thêm, sửa, xóa script JS")
                            }
                        }

                        Toggle(isOn: Binding(
                            get: { currentWindowMode },
                            set: { _ in onToggleWindowMode?() }
                        )) {
                            SettingRow(icon: "macwindow", tint: .orange, title: "Chế độ Cửa sổ", subtitle: "Hiển thị tab dưới dạng lưới — giống Safari Tab Grid")
                        }

                        Toggle(isOn: Binding(
                            get: { currentFloatingMode },
                            set: { _ in onToggleFloatingMode?() }
                        )) {
                            SettingRow(icon: "macwindow.on.rectangle", tint: .cyan, title: "Cửa sổ nổi (Desktop)", subtitle: "Cửa sổ nhỏ có thể kéo — giống máy tính để bàn")
                        }

                        Toggle(isOn: $developerToolsEnabled) {
                            SettingRow(icon: "wrench.and.screwdriver", tint: .purple, title: "Developer Tools (F12)", subtitle: "Xem thông tin trang, source code, console, storage")
                        }
                        if developerToolsEnabled {
                            Button(action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    onOpenDeveloperTools?()
                                }
                            }) {
                                SettingRow(icon: "terminal", tint: .green, title: "Mở Developer Tools", subtitle: "Xem source, console, cookies, storage")
                            }
                        }
                    } header: {
                        Text("Tiện ích mở rộng")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        Button(action: requestNewSession) {
                            SettingRow(icon: "arrow.triangle.2.circlepath", tint: .blue, title: "Bắt đầu phiên mới", subtitle: "Xoá dữ liệu & về trang chủ ngay lập tức")
                        }
                        Button(role: .destructive, action: requestClearData) {
                            SettingRow(icon: "flame.fill", tint: .red, title: "Xoá sạch dữ liệu duyệt web", subtitle: "Cookie, cache, localStorage — không thể hoàn tác")
                        }
                    } header: {
                        Text("Dữ liệu")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onShowAbout()
                            }
                        }) {
                            SettingRow(icon: "info.circle", tint: .cyan, title: "Giới thiệu về Private Browser")
                        }
                        HStack {
                            SettingRow(icon: "number", tint: .gray, title: "Phiên bản")
                            Spacer()
                            Text(AppInfo.versionString)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    } header: {
                        Text("Thông tin")
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)

                if showClearedToast {
                    ToastView(text: "Đã xoá sạch dữ liệu duyệt web")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if showNewSessionToast {
                    ToastView(text: "Đã bắt đầu phiên mới")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
            .alert("Xoá sạch dữ liệu?", isPresented: $showClearConfirm) {
                Button("Hủy", role: .cancel) {}
                Button("Xoá", role: .destructive) { performClearData() }
            } message: {
                Text("Toàn bộ cookie, cache và dữ liệu duyệt web sẽ bị xoá vĩnh viễn.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func requestClearData() {
        if confirmClearData {
            showClearConfirm = true
        } else {
            performClearData()
        }
    }

    private func performClearData() {
        onClearData()
        withAnimation { showClearedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showClearedToast = false }
        }
    }

    private func requestNewSession() {
        onNewSession()
        withAnimation { showNewSessionToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showNewSessionToast = false }
        }
    }
}

private struct SettingRow: View {
    let icon: String
    var tint: Color = .cyan
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}
