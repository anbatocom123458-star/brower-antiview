import Foundation

/// Đánh giá mức độ riêng tư của trang web (A-F) dựa trên các yếu tố:
/// HTTPS, tracker count, fingerprint risk, cookie usage.
/// v4.1: Privacy Grade real-time hiển thị trên URL bar.
final class PrivacyGradeManager: ObservableObject {
    @Published var currentGrade: PrivacyGrade = .a
    @Published var trackersBlocked: Int = 0
    @Published var httpsEnabled: Bool = false

    static let shared = PrivacyGradeManager()

    enum PrivacyGrade: String, CaseIterable {
        case a = "A"
        case b = "B"
        case c = "C"
        case d = "D"
        case f = "F"

        var color: String {
            switch self {
            case .a: return "4CAF50"
            case .b: return "8BC34A"
            case .c: return "FFC107"
            case .d: return "FF9800"
            case .f: return "F44336"
            }
        }

        var description: String {
            switch self {
            case .a: return "Xuất sắc — Không theo dõi"
            case .b: return "Tốt — Ít theo dõi"
            case .c: return "Trung bình — Một số theo dõi"
            case .d: return "Kém — Nhiều theo dõi"
            case .f: return "Rất kém — Bị theo dõi nặng"
            }
        }
    }

    func evaluate(url: String?, trackerCount: Int, isHTTPS: Bool) {
        trackersBlocked = trackerCount
        httpsEnabled = isHTTPS

        var score = 100
        score -= trackerCount * 5
        if !isHTTPS { score -= 20 }

        switch score {
        case 85...100: currentGrade = .a
        case 70..<85: currentGrade = .b
        case 50..<70: currentGrade = .c
        case 25..<50: currentGrade = .d
        default: currentGrade = .f
        }
    }

    func reset() {
        currentGrade = .a
        trackersBlocked = 0
        httpsEnabled = false
    }
}
