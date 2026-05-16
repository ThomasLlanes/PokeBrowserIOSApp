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
    @Published private(set) var hasMorePages = true

    private let service: BerryServing
    private let cache: BerryCache
    private let pageSize = 20
    private var nextOffset = 0

    init(service: BerryServing? = nil, cache: BerryCache? = nil) {
        self.service = service ?? BerryService()
        self.cache = cache ?? BerryCache()
    }

    func loadBerries(forceRefresh: Bool = false) async {
        if !forceRefresh, berries.isEmpty, let cached = cache.load() {
            berries = cached
            nextOffset = cached.count
            hasMorePages = cached.count >= pageSize
            print("📦 Loaded \(cached.count) berries from cache")
        }

        if isLoading { return }
        if forceRefresh {
            berries = []
            nextOffset = 0
            hasMorePages = true
        }
        guard hasMorePages else { return }

        isLoading = true
        error = nil

        do {
            let fetched = try await service.fetchBerryList(limit: pageSize, offset: nextOffset)
            appendFetchedPage(fetched)
            cache.save(berries)
        } catch {
            if berries.isEmpty {
                self.error = "Failed to load berries: \(error.localizedDescription)"
            }
            print("❌ Error loading berries: \(error)")
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(currentBerry: Berry?) async {
        guard let currentBerry else {
            await loadBerries()
            return
        }

        let thresholdIndex = berries.index(berries.endIndex, offsetBy: -5, limitedBy: berries.startIndex) ?? berries.startIndex
        guard berries.firstIndex(where: { $0.id == currentBerry.id }) == thresholdIndex || berries.suffix(5).contains(where: { $0.id == currentBerry.id }) else {
            return
        }

        await loadBerries()
    }

    private func appendFetchedPage(_ fetched: [Berry]) {
        if nextOffset == 0 {
            berries = fetched
            nextOffset = fetched.count
            hasMorePages = fetched.count == pageSize
            return
        }

        let existingNames = Set(berries.map { $0.name.lowercased() })
        let newBerries = fetched.filter { !existingNames.contains($0.name.lowercased()) }
        berries.append(contentsOf: newBerries)
        nextOffset += fetched.count
        hasMorePages = fetched.count == pageSize
    }
}
