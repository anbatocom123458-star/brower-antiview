import UIKit

/// Bảo vệ clipboard — phát hiện khi app khác đọc clipboard, tự xóa dữ liệu nhạy cảm.
/// v4.1: Clipboard monitoring + auto-clear sau 30s.
final class ClipboardGuard: ObservableObject {
    @Published var lastCopiedURL: String?
    @Published var isMonitoring: Bool = false

    static let shared = ClipboardGuard()

    private var timer: Timer?

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    func clearClipboard() {
        UIPasteboard.general.string = nil
        lastCopiedURL = nil
    }

    private func checkClipboard() {
        guard let text = UIPasteboard.general.string,
              text != lastCopiedURL else { return }
        lastCopiedURL = text
        // Auto-clear sau 30s nếu là URL
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                if UIPasteboard.general.string == text {
                    self?.clearClipboard()
                }
            }
        }
    }
}
