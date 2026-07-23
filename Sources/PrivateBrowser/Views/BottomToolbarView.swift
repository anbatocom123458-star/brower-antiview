import SwiftUI
import UIKit

/// Thanh công cụ dưới cùng: back / forward / reload-stop / tab / zoom / devtools / download / menu riêng.
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
    var onOpenDownloads: () -> Void = {}
    var onOpenDeveloperTools: () -> Void = {}
    var onPanicClear: () -> Void = {}
    var onFindInPage: () -> Void = {}
    var onBookmark: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    var body: some View {
        AdaptiveGlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ToolbarButton(icon: "arrow.left", isEnabled: controller.canGoBack, action: {
                    HapticManager.impact(.light)
                    onBack()
                })

                ToolbarButton(icon: "arrow.right", isEnabled: controller.canGoForward, action: {
                    HapticManager.impact(.light)
                    onForward()
                })

                ToolbarButton(icon: controller.isLoading ? "xmark" : "arrow.clockwise", action: {
                    HapticManager.impact(.light)
                    onReloadOrStop()
                })

                Button(action: {
                    HapticManager.impact(.medium)
                    onOpenTabs()
                }) {
                    TabCountBadge(count: tabCount)
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    HapticManager.impact(.light)
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
                    HapticManager.impact(.light)
                    onOpenDownloads()
                }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    HapticManager.impact(.light)
                    onOpenDeveloperTools()
                }) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }

                // v4.0 Panic Clear Button
                Button(action: {
                    HapticManager.impact(.heavy)
                    onPanicClear()
                }) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red.opacity(0.9))
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    HapticManager.impact(.medium)
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
