//
//  ItemDetailViewModel.swift
//  PokeBrowser
//
//

import Foundation
import Combine

@MainActor
final class ItemDetailViewModel: ObservableObject {
    @Published var detail: ItemDetail?
    @Published var isLoading = false
    @Published var error: String?

    private let service: ItemServing

    init(service: ItemServing? = nil) {
        self.service = service ?? ItemService()
    }

    func load(for item: Item) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let key = item.itemId.map(String.init) ?? item.name
            detail = try await service.fetchItemDetail(idOrName: key)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
