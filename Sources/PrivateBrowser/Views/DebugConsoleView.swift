import SwiftUI

/// Console thống kê/debug vui, mở bằng cách gõ từ khoá bí mật "termenol.on" vào
/// thanh địa chỉ (xem BrowserController.secretDebugKeyword). Đây thuần tuý là một
/// "easter egg" hiển thị thông tin kỹ thuật về phiên làm việc hiện tại — KHÔNG chứa
/// lịch sử duyệt web, KHÔNG chứa URL đã ghé thăm, KHÔNG có cơ chế trì hoãn/đếm ngược
/// nào. Mọi số liệu đọc trực tiếp từ trạng thái runtime hiện có (TabsManager, tiến
/// trình hệ thống), không đọc/ghi bất kỳ kho lưu trữ lịch sử nào vì app này không hề
/// giữ lịch sử duyệt web ở bất cứ đâu (mọi WKWebView dùng nonPersistent data store).
struct DebugConsoleView: View {
    @ObservedObject var tabsManager: TabsManager
    @Environment(\.dismiss) private var dismiss

    @State private var elapsed: TimeInterval = 0
    private let launchTime = ProcessInfo.processInfo.systemUptime
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header

                        consoleBlock(title: "PHIÊN LÀM VIỆC") {
                            row("Số tab đang mở", "\(tabsManager.tabCount)")
                            row("Tab riêng tư", "\(tabsManager.tabs.filter(\.isPrivateMode).count)")
                            row("Thời gian chạy tiến trình", formattedUptime)
                        }

                        consoleBlock(title: "BỘ NHỚ") {
                            row("RAM đang dùng (tiến trình)", memoryUsageString)
                        }

                        consoleBlock(title: "ỨNG DỤNG") {
                            row("Phiên bản", AppInfo.versionString)
                            row("Nền tảng", "iOS \(UIDevice.current.systemVersion)")
                            row("Kiểu máy", UIDevice.current.model)
                        }

                        Text("Console này chỉ đọc thông tin kỹ thuật runtime hiện tại. App không lưu lịch sử duyệt web ở bất kỳ đâu nên không có gì để hiển thị hay xoá ở đây.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.top, 6)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            elapsed = ProcessInfo.processInfo.systemUptime - launchTime
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("termenol.on")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Console thống kê kỹ thuật")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func consoleBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
            VStack(spacing: 0) { content() }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }

    private var formattedUptime: String {
        let totalSeconds = Int(elapsed)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Đọc RAM đang dùng của chính tiến trình app qua task_info — chỉ số kỹ thuật
    /// thuần tuý, không liên quan gì tới nội dung đã duyệt.
    private var memoryUsageString: String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "Không đọc được" }
        let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
        return String(format: "%.1f MB", usedMB)
    }
}
