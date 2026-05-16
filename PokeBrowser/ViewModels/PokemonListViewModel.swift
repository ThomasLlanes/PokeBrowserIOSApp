//
//  PokemonListViewModel.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 28/10/25.
//

import Foundation
import Combine

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var pokemons: [Pokemon] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText: String = ""
    @Published var isSearching = false
    @Published private(set) var hasMorePages = true
    @Published private(set) var remoteSearchResult: Pokemon?

    private let service: PokemonServing
    private let cache: PokemonCache
    private var lastSearchedQuery: String?
    private let pageSize = 20
    private var nextOffset = 0
    
    init(service: PokemonServing? = nil, cache: PokemonCache? = nil) {
        self.service = service ?? PokemonService()
        self.cache = cache ?? PokemonCache()
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
    }

    var filteredPokemons: [Pokemon] {
        let raw = searchText
        let query = normalize(raw)
        guard !query.isEmpty else { return pokemons }
        
        let isNumeric = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: query))
        
        let local = pokemons.filter { p in
            let nameMatch = normalize(p.name).contains(query)
            let idMatch = isNumeric ? String(p.pokemonId ?? -1).contains(query) : false
            return nameMatch || idMatch
        }
        if !local.isEmpty { return local }
        if let remote = remoteSearchResult {
            // Show remote result if it matches by name or ID
            let nameMatch = normalize(remote.name).contains(query)
            let idMatch = isNumeric ? String(remote.pokemonId ?? -1).contains(query) : false
            if nameMatch || idMatch { return [remote] }
        }
        return []
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
            remoteSearchResult = nil
            lastSearchedQuery = nil
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
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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

    func searchIfNeeded() async {
        let raw = searchText
        let query = normalize(raw)
        guard !query.isEmpty else {
            remoteSearchResult = nil
            lastSearchedQuery = nil
            isSearching = false
            return
        }
        let isNumeric = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: query))
        // If local results exist (by name or ID), prefer them
        let localExists = pokemons.contains { p in
            let nameMatch = normalize(p.name).contains(query)
            let idMatch = isNumeric ? String(p.pokemonId ?? -1).contains(query) : false
            return nameMatch || idMatch
        }
        if localExists {
            remoteSearchResult = nil
            return
        }
        // Avoid duplicate searches for same query
        if lastSearchedQuery == query, (remoteSearchResult != nil || isSearching) {
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            // Use raw (un-normalized) but lowercased trimmed for API, allowing numeric IDs too
            let serviceQuery = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let found = try await service.fetchPokemon(named: serviceQuery)
            lastSearchedQuery = query
            remoteSearchResult = found
        } catch {
            remoteSearchResult = nil
            lastSearchedQuery = query
            print("❌ Remote search failed for query '\(query)': \(error)")
        }
    }
}
