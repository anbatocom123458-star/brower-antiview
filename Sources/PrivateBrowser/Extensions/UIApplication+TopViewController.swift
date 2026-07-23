import UIKit

extension UIApplication {
    /// Tìm view controller đang hiển thị trên cùng để trình các UIAlertController
    /// (dialog JS alert/confirm/prompt của WKWebView). Trả về nil an toàn nếu không có
    /// scene nào sẵn sàng — tránh crash khi app đang chuyển trạng thái.
    func topMostViewController() -> UIViewController? {
        guard let keyWindow = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
            let root = keyWindow.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
