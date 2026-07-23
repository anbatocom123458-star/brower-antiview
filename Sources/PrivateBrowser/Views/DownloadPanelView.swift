import SwiftUI

/// Panel hiển thị danh sách file đang tải và đã tải xong.
struct DownloadPanelView: View {
    @ObservedObject var downloadManager: DownloadManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            if downloadManager.activeDownloads.isEmpty && downloadManager.completedDownloads.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        if !downloadManager.activeDownloads.isEmpty {
                            sectionHeader("ĐANG TẢI")
                            ForEach(downloadManager.activeDownloads) { item in
                                activeDownloadRow(item)
                            }
                        }

                        if !downloadManager.completedDownloads.isEmpty {
                            sectionHeader("HOÀN THÀNH")
                            ForEach(downloadManager.completedDownloads.reversed()) { item in
                                completedDownloadRow(item)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Tải xuống")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: {
                downloadManager.clearAll()
            }) {
                Text("Xóa hết")
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.7))
            }
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: 20), strokeOpacity: 0.1)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text("Chưa có file nào")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
            Text("File tải về sẽ hiển thị ở đây")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Sections

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.cyan.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activeDownloadRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.cyan)
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if item.isPrivateMode {
                    Text("Riêng tư — sẽ tự xóa")
                        .font(.system(size: 10))
                        .foregroundColor(.purple.opacity(0.7))
                }
            }

            Spacer()

            Button(action: {
                downloadManager.cancelDownload(id: item.id)
            }) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func completedDownloadRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isPrivateMode ? "eyeglasses" : "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(item.isPrivateMode ? .purple.opacity(0.6) : .green.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let error = item.error {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.red.opacity(0.7))
                } else if item.isPrivateMode {
                    Text("Đã xóa — chế độ riêng tư")
                        .font(.system(size: 10))
                        .foregroundColor(.purple.opacity(0.5))
                } else if let url = item.fileURL {
                    Text(url.lastPathComponent)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(1)
                }
            }

            Spacer()

            if !item.isPrivateMode, item.error == nil, let url = item.fileURL {
                Button(action: {
                    openFile(url)
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan.opacity(0.7))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func openFile(_ url: URL) {
        guard let root = UIApplication.shared.topMostViewController() else { return }
        let controller = UIDocumentInteractionController(url: url)
        controller.presentOpenInMenu(from: root.view.bounds, in: root.view, animated: true)
    }
}
