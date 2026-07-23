import SwiftUI

/// Hiển thị thống kê lưu trữ & bandwidth đã tiết kiệm.
/// v4.1: Compact storage stats card.
struct StorageStatsView: View {
    @ObservedObject var storageMonitor = StorageMonitor.shared
    @ObservedObject var privacyReport = PrivacyReport.shared

    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                icon: "shield.checkered",
                value: "\(privacyReport.totalBlocked)",
                label: "Đã chặn",
                color: .green
            )
            StatItem(
                icon: "arrow.down",
                value: storageMonitor.formattedSaved,
                label: "Tiết kiệm",
                color: .cyan
            )
            StatItem(
                icon: "lock.shield",
                value: "\(privacyReport.privacyScore)%",
                label: "Privacy",
                color: .purple
            )
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}
