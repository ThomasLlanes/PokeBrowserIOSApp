//
//  ItemsListViewModel.swift
//  PokeBrowser
//
//

import Foundation
import Combine

@MainActor
final class ItemsListViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""

    private let service: ItemServing

    init(service: ItemServing? = nil) {
        self.service = service ?? ItemService()
    }

    var filteredItems: [Item] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return items }

        return items.filter {
            $0.name.lowercased().contains(query) || String($0.itemId ?? -1).contains(query)
        }
    }

    func loadItems(forceRefresh: Bool = false) async {
        guard forceRefresh || items.isEmpty else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            items = try await service.fetchItemList()
        } catch {
            if items.isEmpty {
                self.error = "Failed to load items: \(error.localizedDescription)"
            }
            print("Error loading items: \(error)")
        }
    }
}
