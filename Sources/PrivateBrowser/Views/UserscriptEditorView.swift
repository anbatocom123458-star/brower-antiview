import SwiftUI

/// Trình编辑 Userscript — nơi người dùng dán/thêm code JS tự chạy trên trang.
struct UserscriptEditorView: View {
    @ObservedObject var userscriptManager: UserscriptManager
    @Environment(\.dismiss) private var dismiss

    @State private var scriptName = ""
    @State private var scriptDescription = ""
    @State private var scriptSource = ""
    @State private var matchPattern = "*://*/*"
    @State private var runAt: Userscript.InjectionTime = .documentEnd
    @State private var runInFrames: Userscript.FrameTarget = .top
    @State private var isEditing = false
    @State private var editingId: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header
                        scriptListSection
                        newScriptSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Userscript Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }.foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Userscript Manager")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text("Dán code JS tự chạy trên trang — giống Tampermonkey")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            }
        }
        .padding(14)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Script List

    private var scriptListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCRIPTS ĐÃ THÊM (\(userscriptManager.scripts.count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.cyan.opacity(0.7))
                .padding(.horizontal, 4)

            if userscriptManager.scripts.isEmpty {
                emptyState
            } else {
                ForEach(userscriptManager.scripts) { script in
                    scriptRow(script)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.2))
            Text("Chưa có script nào")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
            Text("Thêm script bên dưới để tự động chạy code JavaScript trên trang web")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scriptRow(_ script: Userscript) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(script.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(script.description.isEmpty ? script.matchPatterns.joined(separator: ", ") : script.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                userscriptManager.toggleScript(script)
            }) {
                Image(systemName: script.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(script.isEnabled ? .green : .white.opacity(0.3))
            }

            Button(action: {
                userscriptManager.removeScript(script)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - New Script

    private var newScriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isEditing ? "SỬA SCRIPT" : "THÊM SCRIPT MỚI")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.cyan.opacity(0.7))
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                inputField("Tên script", text: $scriptName, placeholder: "My Script")
                inputField("Mô tả (tùy chọn)", text: $scriptDescription, placeholder: "Mô tả ngắn...")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Code JavaScript")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    TextEditor(text: $scriptSource)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.green)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                inputField("URL Pattern", text: $matchPattern, placeholder: "*://*/*")

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chạy lúc")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        Picker("", selection: $runAt) {
                            Text("Document Start").tag(Userscript.InjectionTime.documentStart)
                            Text("Document End").tag(Userscript.InjectionTime.documentEnd)
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trang")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        Picker("", selection: $runInFrames) {
                            Text("Top frame").tag(Userscript.FrameTarget.top)
                            Text("Tất cả").tag(Userscript.FrameTarget.all)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                HStack(spacing: 10) {
                    Button(action: saveScript) {
                        HStack(spacing: 6) {
                            Image(systemName: isEditing ? "checkmark" : "plus")
                            Text(isEditing ? "Cập nhật" : "Thêm script")
                        }
                    }
                    .adaptiveGlassButton(prominent: true, tint: .cyan)

                    if isEditing {
                        Button(action: resetForm) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                Text("Hủy")
                            }
                        }
                        .adaptiveGlassButton()
                    }
                }
            }
            .padding(14)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func inputField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Actions

    private func saveScript() {
        guard !scriptName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !scriptSource.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let script = Userscript(
            id: editingId ?? UUID(),
            name: scriptName,
            description: scriptDescription,
            source: scriptSource,
            isEnabled: true,
            runAt: runAt,
            runInFrames: runInFrames,
            matchPatterns: [matchPattern]
        )

        userscriptManager.addScript(script)
        resetForm()
    }

    private func resetForm() {
        scriptName = ""
        scriptDescription = ""
        scriptSource = ""
        matchPattern = "*://*/*"
        runAt = .documentEnd
        runInFrames = .top
        isEditing = false
        editingId = nil
    }
}
