import SwiftUI

/// Thông tin chi tiết về trang web hiện tại — privacy grade, permissions, tracker stats.
/// v4.1: Site info sheet hiển thị khi tap vào lock icon.
struct SiteInfoView: View {
    let url: String
    let isSecure: Bool
    let trackerCount: Int
    @ObservedObject var privacyGrade = PrivacyGradeManager.shared
    @ObservedObject var storageMonitor = StorageMonitor.shared
    @Binding var isPresented: Bool

    private var host: String {
        URL(string: url)?.host ?? url
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Privacy Grade
                        VStack(spacing: 8) {
                            PrivacyGradeBadge(grade: privacyGrade.currentGrade)
                                .scaleEffect(2.0)
                            Text(privacyGrade.currentGrade.description)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 24)

                        // Site Info Card
                        VStack(spacing: 0) {
                            SiteInfoRow(icon: "globe", title: "Trang web", value: host)
                            Divider().background(AppTheme.divider)
                            SiteInfoRow(icon: "lock.shield", title: "Bảo mật", value: isSecure ? "HTTPS" : "HTTP (không an toàn)")
                            Divider().background(AppTheme.divider)
                            SiteInfoRow(icon: "shield.checkered", title: "Trình theo dõi đã chặn", value: "\(trackerCount)")
                            Divider().background(AppTheme.divider)
                            SiteInfoRow(icon: "arrow.down", title: "Dữ liệu tiết kiệm", value: storageMonitor.formattedSaved)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)

                        // Privacy Tips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gợi ý bảo mật")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            if !isSecure {
                                TipRow(icon: "exclamationmark.triangle", text: "Trang này không sử dụng HTTPS — dữ liệu có thể bị chặn")
                            }
                            if trackerCount > 5 {
                                TipRow(icon: "eye.slash", text: "Trang này có nhiều trình theo dõi — hãy bật chặn quảng cáo")
                            }
                            TipRow(icon: "shield", text: "Cookie và cache sẽ tự xóa khi đóng tab riêng tư")
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Thông tin trang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { isPresented = false }
                        .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SiteInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
    }
}

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.orange)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
