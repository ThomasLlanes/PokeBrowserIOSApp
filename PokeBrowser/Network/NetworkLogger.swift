//
//  NetworkLogger.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 14/05/26.
//

import Foundation

protocol NetworkLogging {
    func logRequest(_ url: URL)
    func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval)
    func logDecoding<Response>(_ type: Response.Type, duration: TimeInterval)
    func logFailure(_ error: Error, duration: TimeInterval)
}

struct ConsoleNetworkLogger: NetworkLogging {
    let showFullResponse: Bool

    init(showFullResponse: Bool = true){
        self.showFullResponse = showFullResponse
    }

    func logRequest(_ url: URL) {
        print("➡️ GET \(url.absoluteString)")
    }

    func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval) {
        print("⬅️ \(response.statusCode) \(response.url?.absoluteString ?? "") • \(data.count) bytes • \(formatted(duration))")

        guard showFullResponse else { return }

        print("📦 Response body:")
        print(formattedResponseBody(from: data))
    }

    func logDecoding<Response>(_ type: Response.Type, duration: TimeInterval) {
        print("✅ Decoded \(type) • \(formatted(duration))")
    }

    func logFailure(_ error: Error, duration: TimeInterval) {
        print("❌ Network failed • \(formatted(duration)) • \(error.localizedDescription)")
    }

    private func formatted(_ duration: TimeInterval) -> String {
        "\(Int(duration * 1_000)) ms"
    }

    private func formattedResponseBody(from data: Data) -> String {
        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let prettyPrintedData = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys]
            ),
            let prettyPrintedResponse = String(data: prettyPrintedData, encoding: .utf8)
        {
            return prettyPrintedResponse
        }

        return String(data: data, encoding: .utf8) ?? "<Unable to display response body>"
    }
}
