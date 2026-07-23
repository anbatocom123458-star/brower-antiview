import SwiftUI
import UIKit

/// Thanh công cụ dưới cùng: back / forward / reload-stop / tab / zoom / menu riêng.
struct BottomToolbarView: View {
    @ObservedObject var controller: BrowserController
    @ObservedObject var zoomManager: ZoomManager
    var hapticsEnabled: Bool
    var showZoomPanel: Bool
    var tabCount: Int
    var onBack: () -> Void
    var onForward: () -> Void
    var onReloadOrStop: () -> Void
    var onToggleZoom: () -> Void
    var onOpenTabs: () -> Void
    var onOpenMenu: () -> Void

    var body: some View {
        AdaptiveGlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ToolbarButton(icon: "arrow.left", isEnabled: controller.canGoBack, action: {
                    haptic(.light)
                    onBack()
                })

                ToolbarButton(icon: "arrow.right", isEnabled: controller.canGoForward, action: {
                    haptic(.light)
                    onForward()
                })

                ToolbarButton(icon: controller.isLoading ? "xmark" : "arrow.clockwise", action: {
                    haptic(.light)
                    onReloadOrStop()
                })

                Button(action: {
                    haptic(.medium)
                    onOpenTabs()
                }) {
                    TabCountBadge(count: tabCount)
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    haptic(.light)
                    onToggleZoom()
                }) {
                    VStack(spacing: 1) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                        Text("\(Int(zoomManager.currentZoom * 100))%")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(showZoomPanel ? .cyan : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                }

                Button(action: {
                    haptic(.medium)
                    onOpenMenu()
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Icon nút mở lưới tab: hình vuông bo góc viền ngoài, số tab hiện đang mở ở giữa —
/// cùng ngôn ngữ hình ảnh với nút tab của Safari để người dùng nhận ra ngay chức năng.
private struct TabCountBadge: View {
    let count: Int

    private var displayText: String {
        count > 99 ? "99+" : "\(count)"
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .stroke(Color.white.opacity(0.85), lineWidth: 1.6)
            .frame(width: 22, height: 20)
            .overlay(
                Text(displayText)
                    .font(.system(size: count > 9 ? 9 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            )
    }
}

private struct ToolbarButton: View {
    let icon: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(isEnabled ? 0.85 : 0.25))
                .frame(maxWidth: .infinity)
        }
        .disabled(!isEnabled)
    }
}
