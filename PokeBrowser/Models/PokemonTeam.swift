//
//  PokemonTeam.swift
//  PokeBrowser
//

import Foundation

struct PokemonTeam: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var slots: [PokemonTeamSlot]

    init(id: UUID = UUID(), name: String, slots: [PokemonTeamSlot]) {
        self.id = id
        self.name = name
        self.slots = Array(slots.prefix(6))
    }
}

struct PokemonTeamSlot: Codable, Identifiable, Equatable {
    let id: UUID
    var pokemon: TeamPokemon
    var heldItem: TeamItem?

    init(id: UUID = UUID(), pokemon: TeamPokemon, heldItem: TeamItem? = nil) {
        self.id = id
        self.pokemon = pokemon
        self.heldItem = heldItem
    }
}

struct TeamPokemon: Codable, Identifiable, Equatable {
    let name: String
    let url: String

    var id: String { name }

    var pokemonId: Int? {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = trimmed.split(separator: "/").last else { return nil }
        return Int(last)
    }

    var spriteURL: URL? {
        guard let pokemonId else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(pokemonId).png")
    }
}

struct TeamItem: Codable, Identifiable, Equatable {
    let name: String
    let url: String

    var id: String { name }

    var itemId: Int? {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = trimmed.split(separator: "/").last else { return nil }
        return Int(last)
    }

    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/\(name).png")
    }
}

extension TeamPokemon {
    init(_ pokemon: Pokemon) {
        self.init(name: pokemon.name, url: pokemon.url)
    }
}

extension TeamItem {
    init(_ item: Item) {
        self.init(name: item.name, url: item.url)
    }
}
