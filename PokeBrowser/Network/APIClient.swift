//
//  APIClient.swift
//  PokeBrowser
//
//  Created by Codex on 14/05/26.
//

import Foundation

protocol APIClientProtocol {
    func get<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: NetworkLogging?

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        logger: NetworkLogging? = ConsoleNetworkLogger()
    ) {
        self.session = session
        self.decoder = decoder
        self.logger = logger
    }

    func get<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        let startDate = Date()
        logger?.logRequest(endpoint.url)

        do {
            let (data, response) = try await session.data(from: endpoint.url)
            let httpResponse = try validate(response)
            logger?.logResponse(httpResponse, data: data, duration: Date().timeIntervalSince(startDate))

            let decoded = try decoder.decode(Response.self, from: data)
            logger?.logDecoding(Response.self, duration: Date().timeIntervalSince(startDate))
            return decoded
        } catch {
            logger?.logFailure(error, duration: Date().timeIntervalSince(startDate))
            throw error
        }
    }

    private func validate(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpStatus(httpResponse.statusCode)
        }

        return httpResponse
    }
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(404):
            return "The requested resource was not found."
        case .httpStatus(let statusCode):
            return "The server returned status code \(statusCode)."
        }
    }
}
