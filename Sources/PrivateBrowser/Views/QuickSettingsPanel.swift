import SwiftUI

/// Panel cài đặt nhanh — truy cập nhanh các toggle quan trọng từ toolbar.
/// v4.1: Quick settings panel với HTTPS-Only, Night Mode, Font Size.
struct QuickSettingsPanel: View {
    @AppStorage(SettingsKey.blockWebRTC) private var blockWebRTC = true
    @AppStorage(SettingsKey.blockAds) private var blockAds = true
    @AppStorage(SettingsKey.desktopMode) private var desktopMode = false
    @AppStorage(SettingsKey.blockIframe) private var blockIframe = true
    @ObservedObject var nightMode = NightModeManager.shared
    @ObservedObject var fontSizeManager = FontSizeManager.shared
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Cài đặt nhanh")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(AppTheme.divider)

            VStack(spacing: 0) {
                QuickToggle(icon: "wifi.slash", title: "Chặn WebRTC", color: .green, isOn: $blockWebRTC)
                QuickToggle(icon: "shield.slash", title: "Chặn quảng cáo", color: .cyan, isOn: $blockAds)
                QuickToggle(icon: "rectangle.slash", title: "Chặn iframe", color: .pink, isOn: $blockIframe)
                QuickToggle(icon: "desktopcomputer", title: "Chế độ Desktop", color: .blue, isOn: $desktopMode)

                Divider().background(AppTheme.divider).padding(.horizontal, 16)

                // Night Mode
                HStack(spacing: 12) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    Text("Chế độ đêm")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { nightMode.isEnabled },
                        set: { _ in nightMode.toggle() }
                    ))
                    .tint(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Font Size
                HStack(spacing: 12) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 14))
                        .foregroundColor(.purple)
                        .frame(width: 28)
                    Text("Cỡ chữ")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { fontSizeManager.decrease() }) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.purple.opacity(0.7))
                    }
                    Text("\(Int(fontSizeManager.currentScale * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 40)
                    Button(action: { fontSizeManager.increase() }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.purple.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
}

private struct QuickToggle: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
