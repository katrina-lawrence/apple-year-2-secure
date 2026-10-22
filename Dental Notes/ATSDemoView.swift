import Foundation
import SwiftUI

struct ATSDemoView: View {
    private let endpoint = URL(string: "https://httpbingo.org/get")!

    @State private var isLoading = false
    @State private var result: ATSRequestResult?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Protocol", value: "HTTPS")

                VStack(alignment: .leading, spacing: 4) {
                    Text("URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(endpoint.absoluteString)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                }

                Button {
                    Task {
                        await sendRequest()
                    }
                } label: {
                    HStack {
                        Label("Send HTTPS Request", systemImage: "paperplane.fill")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(isLoading)
            } header: {
                Text("Secure Training Request")
            } footer: {
                Text("This request uses HTTPS. ATS remains enabled and no broad transport exception is required.")
            }

            if let result {
                Section("Response") {
                    LabeledContent("Status") {
                        Label("\(result.statusCode)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    LabeledContent("Method", value: result.method)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Returned URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.url)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    LabeledContent(
                        "Data received",
                        value: ByteCountFormatter.string(
                            fromByteCount: Int64(result.byteCount),
                            countStyle: .file
                        )
                    )
                }
            }

            if let errorMessage {
                Section("Request Failed") {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("ATS Demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendRequest() async {
        isLoading = true
        result = nil
        errorMessage = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ATSRequestError.invalidResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw ATSRequestError.httpStatus(httpResponse.statusCode)
            }

            let payload = try JSONDecoder().decode(HTTPBingoGetResponse.self, from: data)
            result = ATSRequestResult(
                statusCode: httpResponse.statusCode,
                method: payload.method,
                url: payload.url,
                byteCount: data.count
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct HTTPBingoGetResponse: Decodable {
    let method: String
    let url: String
}

private struct ATSRequestResult {
    let statusCode: Int
    let method: String
    let url: String
    let byteCount: Int
}

private enum ATSRequestError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let statusCode):
            return "The server returned HTTP \(statusCode)."
        }
    }
}
