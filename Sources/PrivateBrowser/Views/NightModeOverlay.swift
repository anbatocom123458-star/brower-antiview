import SwiftUI

/// Overlay night mode — lớp phủ vàng giảm ánh sáng xanh.
/// v4.1: Full-screen overlay with adjustable intensity.
struct NightModeOverlay: View {
    @ObservedObject var nightMode = NightModeManager.shared

    var body: some View {
        if nightMode.isEnabled {
            Color.orange.opacity(nightMode.intensity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
