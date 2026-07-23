import SwiftUI

/// Thanh địa chỉ + thanh tiến trình tải trang.
struct URLBarView: View {
    @ObservedObject var controller: BrowserController
    @ObservedObject var privacyReport = PrivacyReport.shared
    @ObservedObject var privacyGrade = PrivacyGradeManager.shared
    @Binding var editingText: String
    @FocusState.Binding var isFocused: Bool
    var onSubmit: () -> Void
    var onLockTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ProgressBar(progress: controller.progress, isLoading: controller.isLoading)
                .frame(height: 2)

            HStack(spacing: 10) {
                Button(action: { onLockTap?() }) {
                    Image(systemName: controller.isSecure ? "lock.shield.fill" : "lock.open.fill")
                        .foregroundColor(controller.isSecure ? .green.opacity(0.85) : .orange.opacity(0.85))
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(controller.isSecure ? "Trang an toàn" : "Trang không an toàn")

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
                } else if privacyReport.totalBlocked > 0 {
                    AntiTrackerBadge(count: privacyReport.totalBlocked)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 14),
                tint: controller.isSecure ? nil : .orange
            )
            .padding(.horizontal, 10)
            .padding(.top, 6)
        }
    }
}

// MARK: - v4.0 Anti-Tracker Badge

/// Badge nhỏ hiển thị trên thanh URL bar, đếm số tracker/quảng cáo đã chặn real-time.
private struct AntiTrackerBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 10, weight: .bold))
            Text(formatCount(count))
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.75))
        )
        .accessibilityLabel("\(count) trình theo dõi đã chặn")
    }

    private func formatCount(_ n: Int) -> String {
        n >= 1000 ? "\(n / 1000)K+" : "\(n)"
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
