import SwiftUI

/// Displays model output as literal text. HTML and JavaScript are never interpreted.
struct GeneratedSummaryView: View {
    let summary: String

    var body: some View {
        Text(verbatim: summary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}
