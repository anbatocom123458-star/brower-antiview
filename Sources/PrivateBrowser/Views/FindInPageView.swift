import SwiftUI
import WebKit

/// Tìm kiếm trong trang — Find on Page UI.
/// v4.1: Thanh tìm kiếm với nút prev/next, đếm kết quả.
struct FindInPageView: View {
    @ObservedObject var findManager: FindInPageManager
    var webView: WKWebView?
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))

            TextField("Tìm trong trang...", text: $findManager.query)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    findManager.search(query: findManager.query, in: webView)
                }
                .onChange(of: findManager.query) { newValue in
                    if newValue.isEmpty {
                        findManager.clear(in: webView)
                    } else {
                        findManager.search(query: newValue, in: webView)
                    }
                }

            if findManager.resultCount > 0 {
                Text("\(findManager.currentResult)/\(findManager.resultCount)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.cyan)
            }

            Button(action: { findManager.previous(in: webView) }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .disabled(findManager.resultCount == 0)

            Button(action: { findManager.next(in: webView) }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .disabled(findManager.resultCount == 0)

            Button(action: {
                findManager.clear(in: webView)
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 10)
    }
}
