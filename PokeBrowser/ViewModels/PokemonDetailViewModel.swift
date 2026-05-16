//
//  PokemonDetailViewModel.swift
//  PokeBrowser
//
//

import Foundation
import Combine

@MainActor
final class PokemonDetailViewModel: ObservableObject {
    @Published var detail: PokemonDetail?
    @Published var isLoading = false
    @Published var error: String?

    private let service: PokemonServing

    init(service: PokemonServing? = nil) {
        self.service = service ?? PokemonService()
    }

    func load(for pokemon: Pokemon) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let key = pokemon.pokemonId.map(String.init) ?? pokemon.name
            detail = try await service.fetchPokemonDetail(idOrName: key)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
