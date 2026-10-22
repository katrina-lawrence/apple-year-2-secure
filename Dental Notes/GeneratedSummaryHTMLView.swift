import SwiftUI
import WebKit

// Day 4 starter vulnerability: model-generated summaries are trusted as active HTML.
// Learners observe the risk through the payload supplied in the workshop slides.
struct GeneratedSummaryHTMLView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrappedHTML(body: html), baseURL: nil)
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
