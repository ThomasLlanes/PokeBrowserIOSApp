//
//  BerriesListViewModel.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 31/10/25.
//

import Foundation
import Combine

@MainActor
final class BerriesListViewModel: ObservableObject {
    @Published var berries: [Berry] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText: String = ""

    private let service: BerryServing
    private let cache: BerryCache

    init(service: BerryServing? = nil, cache: BerryCache? = nil) {
        self.service = service ?? BerryService()
        self.cache = cache ?? BerryCache()
    }

    var filteredBerries: [Berry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return berries }
        return berries.filter { $0.name.lowercased().contains(query) || String($0.berryId ?? -1).contains(query) }
    }

    func loadBerries(forceRefresh: Bool = false) async {
        if !forceRefresh, berries.isEmpty, let cached = cache.load() {
            berries = cached
            print("📦 Loaded \(cached.count) berries from cache")
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchBerryList()
            berries = fetched
            cache.save(fetched)
        } catch {
            if berries.isEmpty {
                self.error = "Failed to load berries: \(error.localizedDescription)"
            }
            print("❌ Error loading berries: \(error)")
        }
    }
}
