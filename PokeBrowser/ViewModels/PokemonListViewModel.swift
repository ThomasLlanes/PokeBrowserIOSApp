//
//  PokemonListViewModel.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 28/10/25.
//

import Foundation
import Combine

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var pokemons: [Pokemon] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published private(set) var hasMorePages = true

    private let service: PokemonServing
    private let cache: PokemonCache
    private let pageSize = 20
    private var nextOffset = 0
    
    init(service: PokemonServing? = nil, cache: PokemonCache? = nil) {
        self.service = service ?? PokemonService()
        self.cache = cache ?? PokemonCache()
    }

    func loadPokemon(forceRefresh: Bool = false) async {
        if !forceRefresh, pokemons.isEmpty, let cached = cache.load() {
            pokemons = Array(cached.prefix(pageSize))
            nextOffset = 0
            print("📦 Loaded \(cached.count) Pokémon from cache")
        }
        
        if isLoading { return }
        if forceRefresh {
            pokemons = []
            nextOffset = 0
            hasMorePages = true
        }
        guard hasMorePages else { return }

        isLoading = true
        error = nil // Clear previous errors
        do {
            let fetched = try await service.fetchPokemonList(limit: pageSize, offset: nextOffset)
            appendFetchedPage(fetched)
            cache.save(pokemons)
        } catch {
            if pokemons.isEmpty { // Only show error if nothing to show
                self.error = "Failed to load Pokémon: \(error.localizedDescription)"
            }
            print("❌ Error loading Pokémon: \(error)")
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(currentPokemon: Pokemon?) async {
        guard let currentPokemon else {
            await loadPokemon()
            return
        }

        let thresholdIndex = pokemons.index(pokemons.endIndex, offsetBy: -5, limitedBy: pokemons.startIndex) ?? pokemons.startIndex
        guard pokemons.firstIndex(where: { $0.id == currentPokemon.id }) == thresholdIndex || pokemons.suffix(5).contains(where: { $0.id == currentPokemon.id }) else {
            return
        }

        await loadPokemon()
    }

    private func appendFetchedPage(_ fetched: [Pokemon]) {
        if nextOffset == 0 {
            pokemons = fetched
            nextOffset = fetched.count
            hasMorePages = fetched.count == pageSize
            return
        }

        let existingNames = Set(pokemons.map { $0.name.lowercased() })
        let newPokemon = fetched.filter { !existingNames.contains($0.name.lowercased()) }
        pokemons.append(contentsOf: newPokemon)
        nextOffset += fetched.count
        hasMorePages = fetched.count == pageSize
    }
}
