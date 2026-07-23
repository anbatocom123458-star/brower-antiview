import SwiftUI
import WebKit

/// Quản lý chế độ đọc thông minh (Reader Mode) — lọc bỏ quảng cáo, menu rác,
/// chỉ giữ lại nội dung chính của bài viết với font chữ dễ đọc.
///
/// v4.0: Smart Reader Mode with AI-powered article summarization.
final class ReaderModeManager: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var lastError: String?

    static let shared = ReaderModeManager()

    private init() {}

    // MARK: - Extract Article Content via JavaScript

    /// Trích xuất nội dung bài viết từ WKWebView bằng JS injection.
    /// Sử dụng Readability-like algorithm: tìm bài viết chính,
    /// bỏ qua header/footer/sidebar/ads.
    func extractArticle(
        from webView: WKWebView,
        completion: @escaping (ReaderContent?) -> Void
    ) {
        isProcessing = true
        lastError = nil

        // JavaScript to extract main article content
        let extractionJS = """
        (function() {
            // Find the main article content
            var article = document.querySelector('article')
                || document.querySelector('[role="main"]')
                || document.querySelector('.post-content, .article-content, .entry-content, .story-body, .article-body')
                || document.querySelector('main');

            if (!article) {
                // Fallback: find largest text block
                var paragraphs = document.querySelectorAll('p');
                if (paragraphs.length < 3) {
                    return JSON.stringify({
                        success: false,
                        error: 'No article content found'
                    });
                }
                article = paragraphs[0].closest('div') || paragraphs[0].parentElement;
            }

            // Extract title
            var title = '';
            var titleEl = article.querySelector('h1')
                || document.querySelector('h1')
                || document.querySelector('meta[property="og:title"]');
            if (titleEl) {
                title = titleEl.getAttribute('content') || titleEl.textContent || '';
            }
            if (!title) {
                title = document.title || '';
            }

            // Extract author
            var author = '';
            var authorEl = article.querySelector('[rel="author"], .author, .byline, [class*="author"]');
            if (authorEl) {
                author = authorEl.textContent || '';
            }

            // Extract images (keep meaningful ones, skip icons/avatars)
            var images = [];
            var imgEls = article.querySelectorAll('img');
            for (var i = 0; i < Math.min(imgEls.length, 5); i++) {
                var src = imgEls[i].getAttribute('src') || imgEls[i].getAttribute('data-src');
                var alt = imgEls[i].getAttribute('alt') || '';
                if (src && imgEls[i].width > 100 && imgEls[i].height > 60) {
                    images.push({ src: src, alt: alt });
                }
            }

            // Extract text paragraphs
            var paragraphs = article.querySelectorAll('p, h2, h3, h4, blockquote');
            var content = [];
            for (var j = 0; j < paragraphs.length; j++) {
                var text = paragraphs[j].textContent.trim();
                if (text.length > 20) {
                    var type = paragraphs[j].tagName.toLowerCase();
                    if (type === 'h2' || type === 'h3' || type === 'h4') {
                        content.push({ type: 'heading', text: text });
                    } else if (type === 'blockquote') {
                        content.push({ type: 'quote', text: text });
                    } else {
                        content.push({ type: 'paragraph', text: text });
                    }
                }
            }

            if (content.length === 0) {
                return JSON.stringify({
                    success: false,
                    error: 'Article too short or no readable content'
                });
            }

            return JSON.stringify({
                success: true,
                title: title.trim(),
                author: author.trim(),
                images: images,
                content: content,
                url: window.location.href,
                siteName: document.querySelector('meta[property="og:site_name"]')?.content || ''
            });
        })()
        """

        webView.evaluateJavaScript(extractionJS) { result, error in
            DispatchQueue.main.async {
                self.isProcessing = false

                if let error = error {
                    self.lastError = error.localizedDescription
                    completion(nil)
                    return
                }

                guard let jsonString = result as? String,
                      let data = jsonString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool, success else {
                    if let data = (result as? String)?.data(using: .utf8),
                       let fallback = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.lastError = fallback["error"] as? String ?? "Failed to extract content"
                    } else {
                        self.lastError = "Failed to extract content"
                    }
                    completion(nil)
                    return
                }

                let title = json["title"] as? String ?? ""
                let author = json["author"] as? String ?? ""
                let url = json["url"] as? String ?? ""
                let siteName = json["siteName"] as? String ?? ""

                let rawImages = json["images"] as? [[String: String]] ?? []
                let images = rawImages.compactMap { dict -> ReaderImage? in
                    guard let src = dict["src"] else { return nil }
                    return ReaderImage(url: src, alt: dict["alt"] ?? "")
                }

                let rawContent = json["content"] as? [[String: String]] ?? []
                let content = rawContent.compactMap { dict -> ReaderBlock? in
                    guard let text = dict["text"], let typeStr = dict["type"] else { return nil }
                    let type: ReaderBlock.BlockType
                    switch typeStr {
                    case "heading": type = .heading
                    case "quote": type = .quote
                    default: type = .paragraph
                    }
                    return ReaderBlock(type: type, text: text)
                }

                let readerContent = ReaderContent(
                    title: title,
                    author: author,
                    url: url,
                    siteName: siteName,
                    images: images,
                    content: content
                )

                completion(readerContent)
            }
        }
    }

    // MARK: - AI Article Summary (Simulated)

    /// Tóm tắt bài viết bằng AI (giả lập — trích xuất key sentences).
    /// Trong production, có thể gọi API thật (OpenAI/Claude).
    func summarizeArticle(
        _ content: ReaderContent,
        completion: @escaping (String) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.5) {
            // Simulate AI summarization by extracting key points
            var summary = "## Tóm tắt bài viết\n\n"

            // Extract key sentences from paragraphs
            let paragraphs = content.content.filter { $0.type == .paragraph && $0.text.count > 30 }
            let headings = content.content.filter { $0.type == .heading }

            if !headings.isEmpty {
                summary += "**Chủ đề chính:** \(headings[0].text)\n\n"
            }

            // Take first meaningful paragraphs as key points
            let keyPoints = Array(paragraphs.prefix(5))
            summary += "**Các ý chính:**\n\n"

            for (index, paragraph) in keyPoints.enumerated() {
                // Extract first sentence or first 150 chars
                let sentence = Self.extractKeySentence(from: paragraph.text)
                summary += "\(index + 1). \(sentence)\n\n"
            }

            if content.author.isEmpty == false {
                summary += "---\n*Tác giả: \(content.author)*\n"
            }
            if content.siteName.isEmpty == false {
                summary += "*Nguồn: \(content.siteName)*\n"
            }

            DispatchQueue.main.async {
                completion(summary)
            }
        }
    }

    private static func extractKeySentence(from text: String) -> String {
        // Try to get first sentence
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!？！"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 15 }

        if let first = sentences.first {
            return first.count > 150 ? String(first.prefix(147)) + "..." : first
        }
        return text.count > 150 ? String(text.prefix(147)) + "..." : text
    }
}

// MARK: - Reader Content Models

struct ReaderContent {
    let title: String
    let author: String
    let url: String
    let siteName: String
    let images: [ReaderImage]
    let content: [ReaderBlock]
}

struct ReaderBlock: Identifiable {
    let id = UUID()
    let type: BlockType
    let text: String

    enum BlockType {
        case paragraph, heading, quote
    }
}

struct ReaderImage: Identifiable {
    let id = UUID()
    let url: String
    let alt: String
}
