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
    @Published private(set) var hasMorePages = true

    private let service: ItemServing
    private let pageSize = 20
    private var nextOffset = 0

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
        if isLoading { return }
        if forceRefresh {
            items = []
            nextOffset = 0
            hasMorePages = true
        }
        guard hasMorePages else { return }

        isLoading = true
        error = nil

        do {
            let fetched = try await service.fetchItemList(limit: pageSize, offset: nextOffset)
            appendFetchedPage(fetched)
        } catch {
            if items.isEmpty {
                self.error = "Failed to load items: \(error.localizedDescription)"
            }
            print("Error loading items: \(error)")
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(currentItem: Item?) async {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let currentItem else {
            await loadItems()
            return
        }

        let thresholdIndex = items.index(items.endIndex, offsetBy: -5, limitedBy: items.startIndex) ?? items.startIndex
        guard items.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex || items.suffix(5).contains(where: { $0.id == currentItem.id }) else {
            return
        }

        await loadItems()
    }

    private func appendFetchedPage(_ fetched: [Item]) {
        if nextOffset == 0 {
            items = fetched
            nextOffset = fetched.count
            hasMorePages = fetched.count == pageSize
            return
        }

        let existingNames = Set(items.map { $0.name.lowercased() })
        let newItems = fetched.filter { !existingNames.contains($0.name.lowercased()) }
        items.append(contentsOf: newItems)
        nextOffset += fetched.count
        hasMorePages = fetched.count == pageSize
    }
}
