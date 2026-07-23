import SwiftUI

struct FloatingModeView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var floatingManager: FloatingWindowManager
    @ObservedObject var zoomManager: ZoomManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var hapticsEnabled: Bool
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            backgroundGradient

            ForEach(tabsManager.tabs) { tab in
                if tab.isFloating {
                    FloatingWindowView(
                        tab: tab,
                        floatingManager: floatingManager,
                        tabsManager: tabsManager,
                        zoomManager: zoomManager,
                        blockWebRTC: blockWebRTC,
                        blockIframe: blockIframe,
                        blockAds: blockAds,
                        desktopMode: desktopMode,
                        hapticsEnabled: hapticsEnabled
                    )
                }
            }

            FloatingDockView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                zoomManager: zoomManager,
                blockWebRTC: blockWebRTC,
                blockIframe: blockIframe,
                blockAds: blockAds,
                desktopMode: desktopMode,
                hapticsEnabled: hapticsEnabled,
                onExitFloatingMode: {
                    haptic(.heavy)
                    floatingManager.exitFloatingMode(to: tabsManager)
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            floatingManager.enterFloatingMode(from: tabsManager)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")],
            startPoint: .top, endPoint: .bottom
        )
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Preview

struct FloatingModeView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingModeView(
            tabsManager: TabsManager(),
            floatingManager: FloatingWindowManager(),
            zoomManager: ZoomManager(),
            blockWebRTC: false,
            blockIframe: false,
            blockAds: false,
            desktopMode: false,
            hapticsEnabled: true,
            isPresented: .constant(true)
        )
    }
}
