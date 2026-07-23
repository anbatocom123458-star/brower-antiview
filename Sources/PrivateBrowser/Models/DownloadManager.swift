import Foundation
import WebKit

/// Quản lý tải xuống file từ WKWebView — hỗ trợ cả chế độ thường (lưu file) và riêng tư (tự xóa).
final class DownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    @Published var activeDownloads: [DownloadItem] = []
    @Published var completedDownloads: [DownloadItem] = []
    @Published var showDownloadPanel = false

    private var downloadContinuations: [UUID: WKDownload] = [:]
    private var downloadDelegates: [UUID: DownloadDelegateHandler] = [:]
    private var destinationURLs: [UUID: URL] = [:]
    private let lock = NSLock()

    static let shared = DownloadManager()

    /// Thư mục Downloads
    static var downloadsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func startDownload(_ download: WKDownload, fromURL url: URL?, filename: String, isPrivateMode: Bool) {
        let id = UUID()
        let item = DownloadItem(
            id: id,
            filename: filename,
            url: url,
            isPrivateMode: isPrivateMode,
            startedAt: Date()
        )

        lock.lock()
        downloadContinuations[id] = download
        lock.unlock()

        DispatchQueue.main.async {
            self.activeDownloads.append(item)
        }

        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        lock.lock()
        let id = downloadContinuations.first(where: { $0.value === download })?.key
        lock.unlock()

        guard let id else {
            completionHandler(nil)
            return
        }

        let destination = Self.downloadsDirectory.appendingPathComponent(suggestedFilename)
        lock.lock()
        destinationURLs[id] = destination
        lock.unlock()
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        lock.lock()
        let id = downloadContinuations.first(where: { $0.value === download })?.key
        lock.unlock()

        guard let id else { return }

        lock.lock()
        let destination = destinationURLs[id]
        lock.unlock()

        DispatchQueue.main.async {
            if let index = self.activeDownloads.firstIndex(where: { $0.id == id }) {
                var item = self.activeDownloads.remove(at: index)
                item.completedAt = Date()
                item.fileURL = destination
                self.completedDownloads.append(item)

                // Xóa file nếu ở chế độ riêng tư
                if item.isPrivateMode, let url = item.fileURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            self.lock.lock()
            self.downloadContinuations.removeValue(forKey: id)
            self.destinationURLs.removeValue(forKey: id)
            self.lock.unlock()
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error) {
        lock.lock()
        let id = downloadContinuations.first(where: { $0.value === download })?.key
        lock.unlock()

        guard let id else { return }

        DispatchQueue.main.async {
            if let index = self.activeDownloads.firstIndex(where: { $0.id == id }) {
                var item = self.activeDownloads.remove(at: index)
                item.error = error.localizedDescription
                item.completedAt = Date()
                self.completedDownloads.append(item)
            }
            self.lock.lock()
            self.downloadContinuations.removeValue(forKey: id)
            self.destinationURLs.removeValue(forKey: id)
            self.lock.unlock()
        }
    }

    func downloadDidCancel(_ download: WKDownload) {
        lock.lock()
        let id = downloadContinuations.first(where: { $0.value === download })?.key
        lock.unlock()

        guard let id else { return }

        DispatchQueue.main.async {
            self.activeDownloads.removeAll { $0.id == id }
        }
        lock.lock()
        downloadContinuations.removeValue(forKey: id)
        destinationURLs.removeValue(forKey: id)
        lock.unlock()
    }

    /// Xóa tất cả file đã tải ở chế độ riêng tư
    func clearPrivateDownloads() {
        for item in completedDownloads where item.isPrivateMode {
            if let url = item.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        completedDownloads.removeAll { $0.isPrivateMode }
    }

    /// Xóa toàn bộ lịch sử tải
    func clearAll() {
        for item in completedDownloads {
            if let url = item.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        completedDownloads.removeAll()
        activeDownloads.removeAll()
    }

    func cancelDownload(id: UUID) {
        lock.lock()
        downloadContinuations[id]?.cancel()
        downloadContinuations.removeValue(forKey: id)
        destinationURLs.removeValue(forKey: id)
        lock.unlock()
        DispatchQueue.main.async {
            self.activeDownloads.removeAll { $0.id == id }
        }
    }

    /// Thêm item đã hoàn thành (dùng cho download qua URLSession)
    func addCompletedItem(_ item: DownloadItem) {
        DispatchQueue.main.async {
            self.completedDownloads.append(item)
            if item.isPrivateMode, let url = item.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

struct DownloadItem: Identifiable {
    let id: UUID
    let filename: String
    let url: URL?
    let isPrivateMode: Bool
    let startedAt: Date
    var completedAt: Date?
    var fileURL: URL?
    var error: String?

    var status: DownloadStatus {
        if let error { return .failed(error) }
        if completedAt != nil { return .completed }
        return .downloading
    }

    enum DownloadStatus {
        case downloading
        case completed
        case failed(String)
    }
}

/// Delegate handler riêng để giữ reference đúng cách
private class DownloadDelegateHandler: NSObject, WKDownloadDelegate {
    let manager: DownloadManager
    init(manager: DownloadManager) { self.manager = manager }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        manager.download(download, decideDestinationUsing: response, suggestedFilename: suggestedFilename, completionHandler: completionHandler)
    }

    func downloadDidFinish(_ download: WKDownload) {
        manager.downloadDidFinish(download)
    }

    func download(_ download: WKDownload, didFailWithError error: Error) {
        manager.download(download, didFailWithError: error)
    }

    func downloadDidCancel(_ download: WKDownload) {
        manager.downloadDidCancel(download)
    }
}
