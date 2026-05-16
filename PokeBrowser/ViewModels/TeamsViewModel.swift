//
//  TeamsViewModel.swift
//  PokeBrowser
//

import Foundation
import Combine

@MainActor
final class TeamsViewModel: ObservableObject {
    @Published var teamName = ""
    @Published var selectedSlots: [PokemonTeamSlot] = []
    @Published var pokemon: [Pokemon] = []
    @Published var items: [Item] = []
    @Published var isLoadingPokemon = false
    @Published var isLoadingItems = false
    @Published var error: String?
    @Published private(set) var hasMorePokemonPages = true
    @Published private(set) var hasMoreItemPages = true

    private let pokemonService: PokemonServing
    private let itemService: ItemServing
    private let pageSize = 40
    private var nextPokemonOffset = 0
    private var nextItemOffset = 0

    init(pokemonService: PokemonServing? = nil, itemService: ItemServing? = nil) {
        self.pokemonService = pokemonService ?? PokemonService()
        self.itemService = itemService ?? ItemService()
    }

    var canSaveTeam: Bool {
        !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedSlots.isEmpty
    }

    func isSelected(_ pokemon: Pokemon) -> Bool {
        selectedSlots.contains { $0.pokemon.name == pokemon.name }
    }

    func togglePokemon(_ pokemon: Pokemon) {
        if let index = selectedSlots.firstIndex(where: { $0.pokemon.name == pokemon.name }) {
            selectedSlots.remove(at: index)
            return
        }

        guard selectedSlots.count < 6 else { return }
        selectedSlots.append(PokemonTeamSlot(pokemon: TeamPokemon(pokemon)))
    }

    func setHeldItem(_ item: Item?, for slot: PokemonTeamSlot) {
        guard let index = selectedSlots.firstIndex(where: { $0.id == slot.id }) else { return }
        selectedSlots[index].heldItem = item.map(TeamItem.init)
    }

    func makeTeam() -> PokemonTeam {
        PokemonTeam(
            name: teamName.trimmingCharacters(in: .whitespacesAndNewlines),
            slots: selectedSlots
        )
    }

    func loadPokemon() async {
        if isLoadingPokemon || !hasMorePokemonPages { return }
        isLoadingPokemon = true
        error = nil

        do {
            let fetched = try await pokemonService.fetchPokemonList(limit: pageSize, offset: nextPokemonOffset)
            appendPokemonPage(fetched)
        } catch {
            if pokemon.isEmpty {
                self.error = "Failed to load Pokémon: \(error.localizedDescription)"
            }
            print("Error loading team Pokémon: \(error)")
        }

        isLoadingPokemon = false
    }

    func loadNextPokemonPageIfNeeded(currentPokemon: Pokemon?) async {
        guard let currentPokemon else {
            await loadPokemon()
            return
        }

        let thresholdIndex = pokemon.index(pokemon.endIndex, offsetBy: -8, limitedBy: pokemon.startIndex) ?? pokemon.startIndex
        guard pokemon.firstIndex(where: { $0.id == currentPokemon.id }) == thresholdIndex || pokemon.suffix(8).contains(where: { $0.id == currentPokemon.id }) else {
            return
        }

        await loadPokemon()
    }

    func loadItems() async {
        if isLoadingItems || !hasMoreItemPages { return }
        isLoadingItems = true

        do {
            let fetched = try await itemService.fetchItemList(limit: pageSize, offset: nextItemOffset)
            appendItemPage(fetched)
        } catch {
            print("Error loading team items: \(error)")
        }

        isLoadingItems = false
    }

    func loadNextItemPageIfNeeded(currentItem: Item?) async {
        guard let currentItem else {
            await loadItems()
            return
        }

        let thresholdIndex = items.index(items.endIndex, offsetBy: -8, limitedBy: items.startIndex) ?? items.startIndex
        guard items.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex || items.suffix(8).contains(where: { $0.id == currentItem.id }) else {
            return
        }

        await loadItems()
    }

    private func appendPokemonPage(_ fetched: [Pokemon]) {
        if nextPokemonOffset == 0 {
            pokemon = fetched
        } else {
            let existingNames = Set(pokemon.map { $0.name.lowercased() })
            pokemon.append(contentsOf: fetched.filter { !existingNames.contains($0.name.lowercased()) })
        }

        nextPokemonOffset += fetched.count
        hasMorePokemonPages = fetched.count == pageSize
    }

    private func appendItemPage(_ fetched: [Item]) {
        if nextItemOffset == 0 {
            items = fetched
        } else {
            let existingNames = Set(items.map { $0.name.lowercased() })
            items.append(contentsOf: fetched.filter { !existingNames.contains($0.name.lowercased()) })
        }

        nextItemOffset += fetched.count
        hasMoreItemPages = fetched.count == pageSize
    }
}
