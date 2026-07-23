import Foundation
import WebKit

/// Theo dõi dung lượng dữ liệu đã sử dụng trong phiên.
/// v4.1: Hiển thị storage usage, data saved counter.
final class StorageMonitor: ObservableObject {
    @Published var dataSavedKB: Int = 0
    @Published var requestsBlocked: Int = 0
    @Published var bandwidthSavedKB: Int = 0

    static let shared = StorageMonitor()

    private init() {}

    func recordBlocked(requestSize: Int = 50) {
        requestsBlocked += 1
        bandwidthSavedKB += requestSize / 1024
        dataSavedKB = bandwidthSavedKB
    }

    func reset() {
        dataSavedKB = 0
        requestsBlocked = 0
        bandwidthSavedKB = 0
    }

    var formattedSaved: String {
        if bandwidthSavedKB >= 1024 {
            return String(format: "%.1f MB", Double(bandwidthSavedKB) / 1024.0)
        }
        return "\(bandwidthSavedKB) KB"
    }
}
