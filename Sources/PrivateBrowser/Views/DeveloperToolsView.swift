import SwiftUI
@preconcurrency import WebKit

/// Developer Tools — tính năng F12 trên máy tính, hiển thị thông tin chi tiết về trang web:
/// - Thông tin trang (URL, title, meta tags)
/// - Console log (bắt lỗi JS)
/// - Network request info
/// - HTML source code
/// - Cookie & Storage info
struct DeveloperToolsView: View {
    @ObservedObject var controller: BrowserController
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: DevTab = .info
    @State private var pageSource: String = ""
    @State private var pageInfo: [String: String] = [:]
    @State private var consoleLogs: [ConsoleLog] = []
    @State private var isLoading = false
    @State private var showCopiedToast = false

    enum DevTab: String, CaseIterable {
        case info = "Thông tin"
        case source = "Source"
        case console = "Console"
        case cookies = "Cookies"
        case storage = "Storage"
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    tabPicker
                    tabContent
                }
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: refreshData) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.cyan)
                        }
                        Button("Đóng") { dismiss() }
                            .foregroundColor(.cyan)
                    }
                }
            }
            .onAppear { refreshData() }
            .overlay(alignment: .top) {
                if showCopiedToast {
                    ToastView(text: "Đã sao chép")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DevTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .cyan : .white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            switch selectedTab {
            case .info:
                infoTab
            case .source:
                sourceTab
            case .console:
                consoleTab
            case .cookies:
                cookiesTab
            case .storage:
                storageTab
            }
        }
    }

    // MARK: - Info Tab

    private var infoTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            devSection(title: "PAGE INFO") {
                ForEach(Array(pageInfo.keys.sorted()), id: \.self) { key in
                    devRow(key, pageInfo[key] ?? "N/A")
                }
            }

            devSection(title: "SECURITY") {
                devRow("Scheme", controller.urlString.hasPrefix("https") ? "HTTPS (Bảo mật)" : "HTTP (Không bảo mật)")
                devRow("Secure", controller.isSecure ? "Yes" : "No")
            }

            devSection(title: "NAVIGATION") {
                devRow("Can Go Back", controller.canGoBack ? "Yes" : "No")
                devRow("Can Go Forward", controller.canGoForward ? "Yes" : "No")
                devRow("Is Loading", controller.isLoading ? "Yes" : "No")
                if controller.progress > 0 {
                    devRow("Progress", "\(Int(controller.progress * 100))%")
                }
            }
        }
        .padding(16)
    }

    // MARK: - Source Tab

    private var sourceTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HTML SOURCE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan.opacity(0.7))
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = pageSource
                    withAnimation {
                        showCopiedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopiedToast = false }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)
                }
            }

            if pageSource.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Đang tải source code...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                    if isLoading {
                        ProgressView()
                            .tint(.cyan)
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(pageSource)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.green.opacity(0.9))
                        .textSelection(.enabled)
                        .padding(12)
                }
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
    }

    // MARK: - Console Tab

    private var consoleTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CONSOLE LOG (\(consoleLogs.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan.opacity(0.7))
                Spacer()
                Button(action: { consoleLogs.removeAll() }) {
                    Text("Clear")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            if consoleLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Không có log nào")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Lỗi JavaScript sẽ hiển thị ở đây")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.2))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                VStack(spacing: 4) {
                    ForEach(consoleLogs) { log in
                        consoleRow(log)
                    }
                }
            }
        }
        .padding(16)
    }

    private func consoleRow(_ log: ConsoleLog) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: log.type.icon)
                .font(.system(size: 10))
                .foregroundColor(log.type.color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(5)
                Text(log.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer()
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Cookies Tab

    private var cookiesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            devSection(title: "HTTP COOKIES") {
                Text("Cookie store sử dụng nonPersistent() — không lưu cookie xuống đĩa.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                devRow("Data Store", "Non-Persistent")
                devRow("Cookie Count", "0 (Private mode)")
            }

            devSection(title: "COOKIE POLICY") {
                Text("App này không lưu bất kỳ cookie nào giữa các phiên. Mọi cookie chỉ tồn tại trong bộ nhớ RAM và bị xóa khi đóng tab hoặc app.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }

    // MARK: - Storage Tab

    private var storageTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            devSection(title: "WEB STORAGE") {
                devRow("localStorage", "Non-Persistent (RAM only)")
                devRow("sessionStorage", "Non-Persistent (RAM only)")
                devRow("IndexedDB", "Non-Persistent (RAM only)")
                devRow("Cache API", "Non-Persistent (RAM only)")
            }

            devSection(title: "APP STORAGE") {
                devRow("UserDefaults", "\(UserDefaults.standard.dictionaryRepresentation().count) keys")
                devRow("Tab State", "Đang lưu")
                devRow("Settings", "Đang lưu")
            }

            devSection(title: "PRIVACY MODE") {
                Text("Tất cả dữ liệu web đều được lưu trong nonPersistent() data store — nghĩa là KHÔNG CÓ dữ liệu nào được ghi xuống đĩa cứng. Khi đóng tab hoặc app, toàn bộ cookie, cache, localStorage bị xóa vĩnh viễn.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }

    // MARK: - Helpers

    private func devSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.7))
            VStack(spacing: 0) { content() }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func devRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }

    private func refreshData() {
        isLoading = true
        let group = DispatchGroup()

        group.enter()
        fetchPageInfo { group.leave() }

        group.enter()
        fetchPageSource { group.leave() }

        group.enter()
        fetchConsoleLogs { group.leave() }

        group.notify(queue: .main) {
            self.isLoading = false
        }
    }

    private func fetchPageInfo(completion: @escaping () -> Void) {
        guard let webView = controller.webView else { completion(); return }
        var info: [String: String] = [:]
        info["URL"] = controller.urlString
        info["Title"] = controller.pageTitle.isEmpty ? "N/A" : controller.pageTitle
        info["Protocol"] = URL(string: controller.urlString)?.scheme?.uppercased() ?? "N/A"
        info["Host"] = URL(string: controller.urlString)?.host ?? "N/A"

        let js = """
        (function() {
            var meta = document.querySelector('meta[name="description"]');
            var desc = meta ? meta.getAttribute('content') : 'N/A';
            var ogTitle = document.querySelector('meta[property="og:title"]');
            var title = ogTitle ? ogTitle.getAttribute('content') : document.title;
            return JSON.stringify({description: desc, ogTitle: title, charset: document.characterSet, lang: document.documentElement.lang});
        })()
        """
        webView.evaluateJavaScript(js) { result, _ in
            if let jsonString = result as? String,
               let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                DispatchQueue.main.async {
                    info["Description"] = json["description"] ?? "N/A"
                    info["OG Title"] = json["ogTitle"] ?? "N/A"
                    info["Charset"] = json["charset"] ?? "N/A"
                    info["Language"] = json["lang"] ?? "N/A"
                    self.pageInfo = info
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    self.pageInfo = info
                    completion()
                }
            }
        }
    }

    private func fetchPageSource(completion: @escaping () -> Void) {
        guard let webView = controller.webView else { completion(); return }
        let js = "document.documentElement.outerHTML"
        webView.evaluateJavaScript(js) { result, _ in
            DispatchQueue.main.async {
                self.pageSource = result as? String ?? "Không thể lấy source code"
                completion()
            }
        }
    }

    private func fetchConsoleLogs(completion: @escaping () -> Void) {
        guard let webView = controller.webView else { completion(); return }
        let js = """
        (function() {
            var logs = [];
            try {
                if (window.__devToolsLogs) {
                    logs = window.__devToolsLogs;
                }
            } catch(e) {}
            return JSON.stringify(logs);
        })()
        """
        webView.evaluateJavaScript(js) { result, _ in
            if let jsonString = result as? String,
               let data = jsonString.data(using: .utf8),
               let logs = try? JSONDecoder().decode([ConsoleLog].self, from: data) {
                DispatchQueue.main.async {
                    self.consoleLogs = logs
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}

// MARK: - Console Log Model

struct ConsoleLog: Identifiable, Codable {
    let id: UUID
    let message: String
    let type: LogType
    let timestamp: Date

    init(message: String, type: LogType = .log, timestamp: Date = Date()) {
        self.id = UUID()
        self.message = message
        self.type = type
        self.timestamp = timestamp
    }

    enum LogType: String, Codable {
        case log
        case warn
        case error
        case info

        var icon: String {
            switch self {
            case .log: return "text.alignleft"
            case .warn: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .info: return "info.circle"
            }
        }

        var color: Color {
            switch self {
            case .log: return .white.opacity(0.6)
            case .warn: return .orange
            case .error: return .red
            case .info: return .cyan
            }
        }
    }
}

// MARK: - Toast View

private struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}
