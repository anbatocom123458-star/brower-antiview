import SwiftUI

/// Thanh địa chỉ + thanh tiến trình tải trang.
struct URLBarView: View {
    @ObservedObject var controller: BrowserController
    @Binding var editingText: String
    @FocusState.Binding var isFocused: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProgressBar(progress: controller.progress, isLoading: controller.isLoading)
                .frame(height: 2)

            HStack(spacing: 10) {
                Image(systemName: controller.isSecure ? "lock.shield.fill" : "lock.open.fill")
                    .foregroundColor(controller.isSecure ? .green.opacity(0.85) : .orange.opacity(0.85))
                    .font(.system(size: 14))
                    .accessibilityHidden(true)

                TextField("Nhập URL hoặc tìm kiếm...", text: $editingText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.webSearch)
                    .submitLabel(.go)
                    .focused($isFocused)
                    .onSubmit(onSubmit)
                    .onChange(of: controller.urlString) { newValue in
                        if !isFocused {
                            editingText = newValue
                        }
                    }

                if controller.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.cyan)
                } else if !editingText.isEmpty && isFocused {
                    Button(action: { editingText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.35))
                            .font(.system(size: 15))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 10)
            .padding(.top, 6)
        }
    }
}

private struct ProgressBar: View {
    var progress: Double
    var isLoading: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.05))
                Capsule()
                    .fill(LinearGradient(colors: AppTheme.accentGradient, startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, progress))))
                    .animation(.easeInOut(duration: 0.2), value: progress)
            }
        }
        .opacity(isLoading ? 1 : 0)
    }
}
