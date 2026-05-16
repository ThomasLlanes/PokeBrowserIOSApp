//
//  BerryService.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 31/10/25.
//

import Foundation

protocol BerryServing {
    func fetchBerryList(limit: Int, offset: Int) async throws -> [Berry]
    func fetchBerryDetail(idOrName: String) async throws -> BerryDetail
}

final class BerryService: BerryServing {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchBerryList(limit: Int, offset: Int) async throws -> [Berry] {
        let decoded: PokeAPIListResponse<Berry> = try await apiClient.get(.berryList(limit: limit, offset: offset))
        return decoded.results
    }

    func fetchBerryDetail(idOrName: String) async throws -> BerryDetail {
        let normalized = idOrName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try await apiClient.get(.berryDetail(idOrName: normalized))
    }
}
