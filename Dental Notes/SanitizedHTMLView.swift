import SwiftUI
import SwiftSoup
import WebKit

// Central sanitizer entry point for user-authored note/followup HTML.
func sanitizeDentalHTML(_ raw: String) -> String {
    do {
        let whitelist = try Whitelist.none().addTags("b", "i", "h1")
        return try SwiftSoup.clean(raw, whitelist) ?? escapeHTML(raw)
    } catch {
        return escapeHTML(raw)
    }
}

private func escapeHTML(_ text: String) -> String {
    text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

struct SanitizedHTMLView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let sanitizedBody = sanitizeDentalHTML(html)
        webView.loadHTMLString(wrappedHTML(body: sanitizedBody), baseURL: nil)
    }

    private func wrappedHTML(body: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
          <style>
            :root { color-scheme: light dark; }
            body {
              margin: 0;
              padding: 0;
              font: -apple-system-body;
              color: -apple-system-label;
              background: transparent;
            }
            .content {
              white-space: pre-wrap;
              overflow-wrap: anywhere;
              line-height: 1.35;
            }
            h1 {
              font-size: 1.35rem;
              margin: 0 0 0.5rem 0;
              line-height: 1.25;
            }
          </style>
        </head>
        <body>
          <div class="content">\(body)</div>
        </body>
        </html>
        """
    }
}
