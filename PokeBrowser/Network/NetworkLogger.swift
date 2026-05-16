//
//  NetworkLogger.swift
//  PokeBrowser
//
//  Created by Codex on 14/05/26.
//

import Foundation

protocol NetworkLogging {
    func logRequest(_ url: URL)
    func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval)
    func logDecoding<Response>(_ type: Response.Type, duration: TimeInterval)
    func logFailure(_ error: Error, duration: TimeInterval)
}

struct ConsoleNetworkLogger: NetworkLogging {
    func logRequest(_ url: URL) {
        print("➡️ GET \(url.absoluteString)")
    }

    func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval) {
        print("⬅️ \(response.statusCode) \(response.url?.absoluteString ?? "") • \(data.count) bytes • \(formatted(duration))")
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
}

