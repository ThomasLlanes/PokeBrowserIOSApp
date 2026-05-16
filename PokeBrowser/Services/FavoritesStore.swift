//
//  FavoritesStore.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 30/10/25.
//

import Foundation
import Combine

struct FavoritePokemon: Codable, Identifiable, Hashable {
    let name: String
    let pokemonURL: String?
    let imageURL: String?

    var id: String { name.lowercased() }

    var pokemon: Pokemon {
        Pokemon(name: name, url: pokemonURL ?? "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())/")
    }
}

final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [FavoritePokemon]
    
    private let defaultsKey = "favoritePokemonEntries"
    private let legacyDefaultsKey = "favoritePokemonNames"
    
    init() {
        if let saved = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([FavoritePokemon].self, from: saved) {
            self.favorites = decoded
        } else if let saved = UserDefaults.standard.array(forKey: legacyDefaultsKey) as? [String] {
            self.favorites = saved.map {
                FavoritePokemon(name: $0, pokemonURL: nil, imageURL: nil)
            }
            persist()
        } else {
            self.favorites = []
        }
    }
    
    func isFavorite(name: String) -> Bool {
        favorites.contains { $0.id == name.lowercased() }
    }
    
    func toggle(name: String) {
        let favorite = FavoritePokemon(name: name.lowercased(), pokemonURL: nil, imageURL: nil)
        toggle(favorite)
    }

    func toggle(pokemon: Pokemon) {
        let favorite = FavoritePokemon(
            name: pokemon.name.lowercased(),
            pokemonURL: pokemon.url,
            imageURL: spriteURL(for: pokemon)?.absoluteString
        )
        toggle(favorite)
    }

    func remove(_ favorite: FavoritePokemon) {
        favorites.removeAll { $0.id == favorite.id }
        persist()
    }

    private func toggle(_ favorite: FavoritePokemon) {
        if let index = favorites.firstIndex(where: { $0.id == favorite.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(favorite)
        }
        persist()
    }

    private func spriteURL(for pokemon: Pokemon) -> URL? {
        guard let id = pokemon.pokemonId else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
    
    private func persist() {
        guard let encoded = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(encoded, forKey: defaultsKey)
    }
}
