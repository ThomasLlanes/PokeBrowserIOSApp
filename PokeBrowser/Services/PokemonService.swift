//
//  PokemonService.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 28/10/25.
//

import Foundation

protocol PokemonServing {
    func fetchPokemonList(limit: Int, offset: Int) async throws -> [Pokemon]
    func fetchPokemon(named name: String) async throws -> Pokemon
    func fetchPokemonDetail(idOrName: String) async throws -> PokemonDetail
}

final class PokemonService: PokemonServing {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchPokemonList(limit: Int, offset: Int) async throws -> [Pokemon] {
        let decoded: PokeAPIListResponse<Pokemon> = try await apiClient.get(.pokemonList(limit: limit, offset: offset))
        return decoded.results
    }
    
    func fetchPokemon(named name: String) async throws -> Pokemon {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let detail: PokemonDetail = try await apiClient.get(.pokemonDetail(idOrName: trimmed))
        return Pokemon(name: detail.name, url: "https://pokeapi.co/api/v2/pokemon/\(detail.id)/")
    }

    func fetchPokemonDetail(idOrName: String) async throws -> PokemonDetail {
        let normalized = idOrName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try await apiClient.get(.pokemonDetail(idOrName: normalized))
    }
}
