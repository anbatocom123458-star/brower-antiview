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
    @AppStorage(SettingsKey.blockFingerprint) private var blockFingerprint = true
    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKey.confirmClearData) private var confirmClearData = true

    @State private var showClearConfirm = false
    @State private var showClearedToast = false

    var onShowAbout: () -> Void
    var onClearData: () -> Void

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
                        Toggle(isOn: $blockFingerprint) {
                            SettingRow(icon: "fingerprint", tint: .purple, title: "Chống dấu vân tay", subtitle: "Giả lập Canvas & WebGL fingerprint")
                        }
                        Toggle(isOn: $blockIframe) {
                            SettingRow(icon: "rectangle.slash", tint: .pink, title: "Chặn iframe", subtitle: "Tự xoá iframe ẩn/theo dõi trên trang")
                        }
                    } header: {
                        Text("Bảo mật & Riêng tư")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
                        Toggle(isOn: $hapticsEnabled) {
                            SettingRow(icon: "hand.tap", tint: .yellow, title: "Phản hồi rung (Haptics)")
                        }
                        Toggle(isOn: $confirmClearData) {
                            SettingRow(icon: "checkmark.shield", tint: .mint, title: "Xác nhận trước khi xoá dữ liệu")
                        }
                    } header: {
                        Text("Trải nghiệm")
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section {
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
