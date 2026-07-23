import SwiftUI

/// Lưới xem trước các tab đang mở, kiểu Safari/Chrome tab switcher. Mỗi thẻ hiện
/// tiêu đề + host của trang trong tab đó (không chụp ảnh preview thật của trang —
/// app này không giữ dữ liệu nào ngoài bộ nhớ tạm của WKWebView, nên "preview" ở
/// đây là preview kiểu thẻ thông tin, không phải screenshot pixel-perfect).
struct TabGridView: View {
    @ObservedObject var tabsManager: TabsManager
    @Binding var isPresented: Bool
    var hapticsEnabled: Bool
    var onOpenNewTab: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tabsManager.tabs) { tab in
                        TabThumbnailCard(
                            tab: tab,
                            isActive: tab.id == tabsManager.activeTabId,
                            canClose: tabsManager.tabCount > 1,
                            onSelect: {
                                haptic(.light)
                                tabsManager.select(tab)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            },
                            onClose: {
                                haptic(.medium)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    tabsManager.close(tab)
                                }
                            }
                        )
                    }

                    NewTabCard(onTap: {
                        haptic(.medium)
                        onOpenNewTab()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    })
                }
                .padding(16)
            }
        }
        .background(
            LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack {
            Text("\(tabsManager.tabCount) Tab")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                haptic(.light)
                onOpenNewTab()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .adaptiveGlass(in: Circle())
            }

            Button(action: {
                haptic(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPresented = false
                }
            }) {
                Text("Xong")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Một thẻ đại diện cho một tab trong lưới: tiêu đề, host, biểu tượng khoá bảo mật,
/// viền sáng khi đang là tab active, nút "x" góc trên để đóng riêng tab đó.
private struct TabThumbnailCard: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let canClose: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                previewArea

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: tab.controller.isSecure ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 8))
                            .foregroundColor(tab.controller.isSecure ? .green.opacity(0.7) : .orange.opacity(0.7))
                        Text(tab.displayHost)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(Color.white.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? Color.cyan.opacity(0.8) : Color.white.opacity(0.08), lineWidth: isActive ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if canClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                }
                .padding(6)
            }
        }
    }

    /// Vùng xem trước phía trên thẻ. Không có screenshot thật của trang (private
    /// browser không giữ ảnh chụp nội dung đã duyệt vì lý do riêng tư), nên hiển thị
    /// icon đại diện lớn + tiến trình tải nếu tab đó đang load — đủ để phân biệt các
    /// tab với nhau mà không rò rỉ nội dung đã xem qua ảnh xem trước như App Switcher.
    /// Không tự clip góc ở đây — card ngoài cùng đã clip toàn bộ 4 góc, tự clip thêm
    /// ở đây sẽ bo luôn 2 góc dưới của preview và để hở khoảng trống hình tam giác
    /// giữa preview và phần text bên dưới (2 shape bo độc lập không khớp pixel nhau).
    private var previewArea: some View {
        ZStack {
            LinearGradient(
                colors: isActive ? [Color.cyan.opacity(0.18), Color.blue.opacity(0.10)] : [Color.white.opacity(0.03), Color.white.opacity(0.01)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if tab.controller.isLoading {
                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(0.9)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .frame(height: 92)
    }
}

/// Thẻ "+" cuối lưới để mở tab mới, cùng kích thước với thẻ tab để lưới đều nhau.
private struct NewTabCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(.white.opacity(0.4))
                Text("Tab mới")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                    .foregroundColor(.white.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}
