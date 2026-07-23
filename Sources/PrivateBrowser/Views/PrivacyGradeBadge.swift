import SwiftUI

/// Badge hiển thị Privacy Grade (A-F) trên URL bar.
/// v4.1: Compact badge với màu sắc tương ứng.
struct PrivacyGradeBadge: View {
    let grade: PrivacyGradeManager.PrivacyGrade

    var body: some View {
        Text(grade.rawValue)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundColor(Color(hex: grade.color))
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(Color(hex: grade.color).opacity(0.15))
            )
            .overlay(
                Circle()
                    .stroke(Color(hex: grade.color).opacity(0.4), lineWidth: 1)
            )
            .accessibilityLabel("Privacy grade: \(grade.rawValue)")
    }
}
