import SwiftUI

/// Phần "Giới thiệu" đầy đủ: icon app, mô tả, danh sách tính năng minh hoạ bằng icon,
/// thông tin phiên bản và ghi chú bảo mật — thay cho bản About sơ sài trước đây.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, detail: String)] = [
        ("eye.slash.fill", "Chế độ riêng tư tuyệt đối", "Không cache, không cookie, không lịch sử — mỗi phiên là một khởi đầu mới."),
        ("wifi.slash", "Chống rò IP & WebRTC", "Chặn WebRTC, GeoLocation, Battery API để hạn chế lộ vị trí và địa chỉ IP thật."),
        ("shield.checkered", "Live Anti-Tracker Counter", "Badge real-time trên thanh URL đếm số tracker/quảng cáo đã chặn trong phiên."),
        ("bolt.fill", "Quick Panic Clear", "Một chạm để đóng toàn bộ tab, xóa cache/cookie và quay về trang Home ngay lập tức."),
        ("magnifyingglass", "Find on Page", "Tìm kiếm text trong trang hiện tại — đếm kết quả, điều hướng giữa các kết quả."),
        ("bookmark", "Bookmark Manager", "Lưu trang yêu thích, xem lại trang đã đóng — quản lý trực quan."),
        ("slider.horizontal.3", "Quick Settings Panel", "Truy cập nhanh các toggle: chặn quảng cáo, chế độ desktop, night mode."),
        ("moon.fill", "Night Mode", "Bộ lọc ánh sáng xanh ban đêm — điều chỉnh cường độ giảm mỏi mắt."),
        ("textformat.size", "Font Size Quick Adjust", "Tăng/giảm cỡ chữ trang web bằng nút +/- trực tiếp."),
        ("star.circle", "Privacy Grade (A-F)", "Đánh giá mức riêng tư trang web real-time trên thanh URL."),
        ("doc.on.clipboard", "Clipboard Guard", "Bảo vệ clipboard — tự xóa URL sao chép sau 30 giây."),
        ("lock.shield", "HTTPS-Only Mode", "Tự chuyển sang HTTPS — không dùng kết nối HTTP không an toàn."),
        ("eye.slash", "Do Not Track Header", "Gửi yêu cầu Do Not Track đến mọi trang web."),
        ("arrow.down.circle", "Storage Monitor", "Theo dõi dung lượng dữ liệu tiết kiệm được trong phiên."),
        ("checkmark.shield", "Site Permission Manager", "Quản lý quyền camera/mic/location theo từng trang web."),
        ("clock", "Recently Closed Tabs", "Khôi phục tab đã đóng — lưu 20 tab gần nhất."),
        ("shield.slash", "Chặn quảng cáo & trình theo dõi", "Chặn ở tầng network bằng WKContentRuleList, tự dọn tham số theo dõi trong URL."),
        ("rectangle.slash", "Chặn iframe theo dõi", "Tự động dọn sạch iframe ẩn/quảng cáo được chèn vào trang."),
        ("record.circle", "Tự ẩn khi bị ghi màn hình", "Phát hiện quay/chụp màn hình và App Switcher, tự động che nội dung ngay lập tức."),
        ("arrow.triangle.2.circlepath", "Phiên mới & tự xoá khi rời app", "Một chạm để bắt đầu lại sạch sẽ, hoặc tự xoá dữ liệu khi chuyển sang app khác."),
        ("sparkles", "Liquid Glass trên iOS 26", "Giao diện kính lỏng mới của Apple, tự thích ứng và vẫn đẹp trên iOS 16 trở lên."),
        ("magnifyingglass", "Zoom linh hoạt 25%–200%", "Điều chỉnh cỡ chữ/trang bằng thanh trượt trực quan, mượt mà."),
        ("sun.max.fill", "Điều chỉnh độ sáng", "Trượt để tăng/giảm độ sáng màn hình trực tiếp từ app — tiết kiệm pin."),
        ("arrow.down.circle", "Tải xuống file", "Tải file trực tiếp từ trình duyệt. File ở chế độ riêng tư tự động xóa khi tải xong."),
        ("chevron.left.forwardslash.chevron.right", "Userscript Manager", "Dán code JS tự chạy trên trang — giống Tampermonkey trên iOS."),
        ("macwindow", "Chế độ Cửa sổ", "Quản lý tab dưới dạng các cửa sổ nhỏ — giống trải nghiệm desktop."),
        ("wrench.and.screwdriver", "Developer Tools (F12)", "Xem source code, console, cookies, storage — giống F12 trên máy tính."),
        ("arrow.clockwise", "Khôi phục phiên", "Tự mở lại tab đã dùng khi khởi động app — không mất dữ liệu."),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            AppIconBadge()

                            Text("Private Browser")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Trình duyệt kín — không lưu lịch sử, không cookie, không iframe, chống lộ IP.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)

                            Text("Phiên bản \(AppInfo.versionString)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .padding(.top, 12)

                        VStack(spacing: 10) {
                            ForEach(features, id: \.title) { feature in
                                FeatureRow(icon: feature.icon, title: feature.title, detail: feature.detail)
                            }
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 6) {
                            Text("Được xây dựng để bảo vệ quyền riêng tư của bạn.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                            Text("© \(AppInfo.currentYear) Private Browser")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Giới thiệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct AppIconBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 84, height: 84)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(colors: AppTheme.accentGradient, startPoint: .top, endPoint: .bottom)
                )
        }
        .shadow(color: .cyan.opacity(0.25), radius: 20)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
    }
}

/// Thông tin phiên bản đọc trực tiếp từ Info.plist — luôn đồng bộ với bundle,
/// không cần sửa tay mỗi lần build.
enum AppInfo {
    static var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    static var currentYear: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(year)
    }
}
