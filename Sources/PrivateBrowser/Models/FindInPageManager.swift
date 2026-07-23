import Foundation
import WebKit

/// Tìm kiếm text trong trang hiện tại (Find on Page).
/// v4.1: Tìm kiếm real-time, đếm kết quả, điều hướng giữa các kết quả.
final class FindInPageManager: ObservableObject {
    @Published var query: String = ""
    @Published var resultCount: Int = 0
    @Published var currentResult: Int = 0
    @Published var isActive: Bool = false

    static let shared = FindInPageManager()

    private init() {}

    func search(query: String, in webView: WKWebView?) {
        self.query = query
        guard let webView, !query.isEmpty else {
            resultCount = 0
            currentResult = 0
            return
        }

        let escapedQuery = query.replacingOccurrences(of: "'", with: "\\'")
        let js = """
        (function() {
            document.querySelectorAll('mark[data-find]').forEach(function(m) {
                var parent = m.parentNode;
                parent.replaceChild(document.createTextNode(m.textContent), m);
                parent.normalize();
            });
            var count = 0;
            var body = document.body;
            var walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
            while (walker.nextNode()) {
                var node = walker.currentNode;
                var idx = node.nodeValue.toLowerCase().indexOf('\(escapedQuery)'.toLowerCase());
                if (idx >= 0) {
                    var range = document.createRange();
                    range.setStart(node, idx);
                    range.setEnd(node, idx + '\(escapedQuery)'.length);
                    var mark = document.createElement('mark');
                    mark.style.background = '#FFD60A';
                    mark.style.color = '#000';
                    mark.setAttribute('data-find', 'true');
                    range.surroundContents(mark);
                    count++;
                }
            }
            return count;
        })()
        """
        webView.evaluateJavaScript(js) { result, _ in
            DispatchQueue.main.async {
                self.resultCount = result as? Int ?? 0
                self.currentResult = self.resultCount > 0 ? 1 : 0
            }
        }
    }

    func next(in webView: WKWebView?) {
        guard resultCount > 0 else { return }
        currentResult = currentResult >= resultCount ? 1 : currentResult + 1
        scrollToResult(currentResult, in: webView)
    }

    func previous(in webView: WKWebView?) {
        guard resultCount > 0 else { return }
        currentResult = currentResult <= 1 ? resultCount : currentResult - 1
        scrollToResult(currentResult, in: webView)
    }

    func clear(in webView: WKWebView?) {
        query = ""
        resultCount = 0
        currentResult = 0
        isActive = false
        webView?.evaluateJavaScript("""
            document.querySelectorAll('mark[data-find]').forEach(function(m) {
                var parent = m.parentNode;
                parent.replaceChild(document.createTextNode(m.textContent), m);
                parent.normalize();
            });
        """)
    }

    private func scrollToResult(_ index: Int, in webView: WKWebView?) {
        webView?.evaluateJavaScript("""
            var marks = document.querySelectorAll('mark[data-find]');
            if (marks.length >= \(index)) {
                marks[\(index - 1)].scrollIntoView({behavior: 'smooth', block: 'center'});
                marks.forEach(function(m, i) {
                    m.style.background = (i === \(index - 1)) ? '#FF6B35' : '#FFD60A';
                });
            }
        """)
    }
}
