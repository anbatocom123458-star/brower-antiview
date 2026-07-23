import Foundation
import LocalAuthentication
@preconcurrency import WebKit

/// Xoá sạch toàn bộ dữ liệu duyệt web và quản lý xác thực sinh trắc học
/// cho tab riêng tư.
///
/// v3.4: Thêm BiometricAuthManager — hỗ trợ Face ID / Touch ID /
/// mật khẩu máy để khóa tab riêng tư.
enum PrivacyManager {
    static func clearAllData(completion: @escaping () -> Void = {}) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let since = Date(timeIntervalSince1970: 0)
        let group = DispatchGroup()

        group.enter()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: since) {
            group.leave()
        }

        group.enter()
        WKWebsiteDataStore.nonPersistent().removeData(ofTypes: types, modifiedSince: since) {
            group.leave()
        }

        group.enter()
        DispatchQueue.main.async {
            URLCache.shared.removeAllCachedResponses()
            if let cookies = HTTPCookieStorage.shared.cookies {
                cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
            }
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}

// MARK: - Biometric Authentication Manager

/// Quản lý xác thực sinh trắc học — Face ID, Touch ID, hoặc mật khẩu máy.
/// Dùng cho việc khóa tab riêng tư: khi người dùng mở/chuyển sang tab riêng tư,
/// yêu cầu xác thực trước khi hiển thị nội dung.
final class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticating: Bool = false
    @Published var isUnlocked: Bool = false
    @Published var authError: String?

    static let shared = BiometricAuthManager()

    private let context = LAContext()
    private var lastPolicyError: NSError?

    private init() {}

    /// Kiểm tra thiết bị có hỗ trợ sinh trắc học không
    var canUseBiometrics: Bool {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Lấy loại sinh trắc học được hỗ trợ
    var biometricType: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Không khả dụng"
        }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Sinh trắc học"
        }
    }

    /// Yêu cầu xác thực — gọi khi mở tab riêng tư hoặc chuyển sang private mode.
    /// completion: (success: Bool) -> Void
    func authenticate(completion: @escaping (Bool) -> Void) {
        guard UserDefaults.standard.bool(forKey: SettingsKey.biometricLockPrivateTabs) else {
            completion(true)
            return
        }

        guard canUseBiometrics else {
            // Không hỗ trợ sinh trắc học — cho phép qua
            completion(true)
            return
        }

        isAuthenticating = true
        authError = nil

        let reason = "Xác thực để truy cập tab riêng tư"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                if success {
                    self?.isUnlocked = true
                    completion(true)
                } else {
                    self?.isUnlocked = false
                    if let laError = error as? LAError {
                        self?.authError = Self.friendlyMessage(for: laError)
                    }
                    completion(false)
                }
            }
        }
    }

    /// Reset trạng thái khóa — gọi khi đóng tab riêng tư
    func lock() {
        isUnlocked = false
        authError = nil
    }

    private static func friendlyMessage(for error: LAError) -> String {
        switch error.code {
        case .userCancel:
            return "Đã hủy xác thực"
        case .userFallback:
            return "Sử dụng mật khẩu máy"
        case .biometryLockout:
            return "Sinh trắc học bị khóa do nhập sai quá nhiều lần"
        case .biometryNotAvailable:
            return "Sinh trắc học không khả dụng"
        case .biometryNotEnrolled:
            return "Chưa thiết lập sinh trắc học trên thiết bị"
        default:
            return "Xác thực thất bại: \(error.localizedDescription)"
        }
    }
}
