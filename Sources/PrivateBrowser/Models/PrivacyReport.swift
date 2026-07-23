import Foundation

/// Theo dõi thống kê privacy — đếm tracker/ad bị chặn, tính privacy score.
final class PrivacyReport: ObservableObject {
    @Published var blockedTrackers: Int = 0
    @Published var blockedAds: Int = 0
    @Published var totalRequests: Int = 0

    static let shared = PrivacyReport()

    private enum Keys {
        static let blockedTrackers = "privacy.blockedTrackers"
        static let blockedAds = "privacy.blockedAds"
        static let totalRequests = "privacy.totalRequests"
    }

    init() {
        blockedTrackers = UserDefaults.standard.integer(forKey: Keys.blockedTrackers)
        blockedAds = UserDefaults.standard.integer(forKey: Keys.blockedAds)
        totalRequests = UserDefaults.standard.integer(forKey: Keys.totalRequests)
    }

    var totalBlocked: Int { blockedTrackers + blockedAds }

    var privacyScore: Int {
        guard totalRequests > 0 else { return 100 }
        let blocked = blockedTrackers + blockedAds
        return min(100, max(0, Int((Double(blocked) / Double(totalRequests)) * 100)))
    }

    var summary: String {
        let blocked = blockedTrackers + blockedAds
        if blocked == 0 {
            return "Chưa chặn nội dung nào trong phiên này."
        }
        return "Đã chặn \(blockedTrackers) trình theo dõi và \(blockedAds) quảng cáo."
    }

    func incrementBlockedTracker() {
        DispatchQueue.main.async {
            self.blockedTrackers += 1
            self.totalRequests += 1
            self.save()
        }
    }

    func incrementBlockedAd() {
        DispatchQueue.main.async {
            self.blockedAds += 1
            self.totalRequests += 1
            self.save()
        }
    }

    func incrementRequest() {
        DispatchQueue.main.async {
            self.totalRequests += 1
            self.save()
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.blockedTrackers = 0
            self.blockedAds = 0
            self.totalRequests = 0
            self.save()
        }
    }

    private func save() {
        UserDefaults.standard.set(blockedTrackers, forKey: Keys.blockedTrackers)
        UserDefaults.standard.set(blockedAds, forKey: Keys.blockedAds)
        UserDefaults.standard.set(totalRequests, forKey: Keys.totalRequests)
    }
}
