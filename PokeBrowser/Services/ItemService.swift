//
//  ItemService.swift
//  PokeBrowser
//
//

import Foundation

protocol ItemServing {
    func fetchItemList(limit: Int, offset: Int) async throws -> [Item]
    func fetchItemDetail(idOrName: String) async throws -> ItemDetail
}

final class ItemService: ItemServing {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchItemList(limit: Int, offset: Int) async throws -> [Item] {
        let decoded: PokeAPIListResponse<Item> = try await apiClient.get(.itemList(limit: limit, offset: offset))
        return decoded.results
    }

    func fetchItemDetail(idOrName: String) async throws -> ItemDetail {
        let normalized = idOrName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try await apiClient.get(.itemDetail(idOrName: normalized))
    }
}
