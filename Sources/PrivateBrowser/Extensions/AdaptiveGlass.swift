import SwiftUI

// MARK: - Adaptive Glass Background Modifier
private struct AdaptiveGlassBackground<S: Shape>: ViewModifier {
    var shape: S
    var tint: Color?
    var strokeOpacity: Double

    func body(content: Content) -> some View {
        content.background(
            ZStack {
                shape.fill(.ultraThinMaterial)
                if let tint = tint {
                    shape.fill(tint.opacity(0.15))
                }
            }
            .overlay(
                shape.stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
        )
    }
}

// MARK: - Adaptive Glass Button Modifier
private struct AdaptiveGlassButtonModifier: ViewModifier {
    var prominent: Bool
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(prominent ? .black : .white.opacity(0.85))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(prominent ? (tint ?? Color.cyan) : Color.white.opacity(0.08))
            )
            .buttonStyle(.plain)
    }
}

// MARK: - Glass Effect Container
struct AdaptiveGlassEffectContainer<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: spacing) {
            content()
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Nền kính mờ thích ứng an toàn trên mọi phiên bản iOS
    func adaptiveGlass<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        strokeOpacity: Double = 0.08
    ) -> some View {
        modifier(AdaptiveGlassBackground(shape: shape, tint: tint, strokeOpacity: strokeOpacity))
    }

    /// Style nút thích ứng an toàn trên mọi phiên bản iOS
    func adaptiveGlassButton(prominent: Bool = false, tint: Color? = nil) -> some View {
        modifier(AdaptiveGlassButtonModifier(prominent: prominent, tint: tint))
    }
}
