import SwiftUI

/// Panel chỉnh zoom trang web, trượt lên từ đáy màn hình.
struct ZoomPanelView: View {
    @ObservedObject var zoomManager: ZoomManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Mức zoom")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            HStack(spacing: 10) {
                Text("25%").font(.caption2).foregroundColor(.gray)
                Slider(value: $zoomManager.currentZoom, in: zoomManager.minZoom...zoomManager.maxZoom, step: zoomManager.step)
                    .tint(.cyan)
                Text("200%").font(.caption2).foregroundColor(.gray)
            }

            HStack(spacing: 16) {
                Text("\(Int(zoomManager.currentZoom * 100))%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)

                Spacer()

                Button(action: { zoomManager.reset() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Đặt lại 100%")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06), in: Capsule())
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 25)
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
        )
    }
}
