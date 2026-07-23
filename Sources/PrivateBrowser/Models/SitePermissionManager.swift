import Foundation

/// Quản lý quyền truy cập theo từng site: camera, microphone, location, notification.
/// v4.1: Site permission manager với memory (không hỏi lại trong phiên).
final class SitePermissionManager: ObservableObject {
    @Published var sitePermissions: [String: SitePermissions] = [:]

    static let shared = SitePermissionManager()

    struct SitePermissions: Codable {
        var camera: PermissionState = .ask
        var microphone: PermissionState = .ask
        var location: PermissionState = .ask
        var notification: PermissionState = .ask
    }

    enum PermissionState: String, Codable {
        case allow, deny, ask
    }

    func getPermission(for host: String, type: String) -> PermissionState {
        guard let perms = sitePermissions[host] else { return .ask }
        switch type {
        case "camera": return perms.camera
        case "microphone": return perms.microphone
        case "location": return perms.location
        case "notification": return perms.notification
        default: return .ask
        }
    }

    func setPermission(for host: String, type: String, state: PermissionState) {
        var perms = sitePermissions[host] ?? SitePermissions()
        switch type {
        case "camera": perms.camera = state
        case "microphone": perms.microphone = state
        case "location": perms.location = state
        case "notification": perms.notification = state
        default: break
        }
        sitePermissions[host] = perms
    }

    func resetAll() {
        sitePermissions.removeAll()
    }

    func resetFor(host: String) {
        sitePermissions.removeValue(forKey: host)
    }
}
