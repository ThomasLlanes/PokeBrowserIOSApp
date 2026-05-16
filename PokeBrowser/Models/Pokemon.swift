//
//  Pokemon.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 28/10/25.
//

import Foundation

struct PokeAPIListResponse<Resource: Codable>: Codable {
    let results: [Resource]
}

struct Pokemon: Codable, Identifiable {
    let name: String
    let url: String
    
    var id: String { name } // Needed for SwiftUI lists
    
    // Extract the trailing numeric ID from the API URL, e.g. "https://pokeapi.co/api/v2/pokemon/25/" -> 25
    var pokemonId: Int? {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = trimmed.split(separator: "/").last else { return nil }
        return Int(last)
    }
}

struct PokemonDetail: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let baseExperience: Int?
    let sprites: PokemonSprites
    let types: [PokemonTypeSlot]
    let abilities: [PokemonAbilitySlot]
    let stats: [PokemonStatSlot]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case height
        case weight
        case baseExperience = "base_experience"
        case sprites
        case types
        case abilities
        case stats
    }
}

struct PokemonSprites: Codable {
    let frontDefault: String?
    let frontShiny: String?
    let backDefault: String?
    let backShiny: String?

    var displaySpriteGroups: [PokemonSpriteGroup] {
        [
            spriteGroup(
                id: "default",
                title: "Default",
                front: frontDefault,
                back: backDefault
            ),
            spriteGroup(
                id: "shiny",
                title: "Shiny",
                front: frontShiny,
                back: backShiny
            )
        ].compactMap { $0 }
    }

    private func spriteGroup(
        id: String,
        title: String,
        front: String?,
        back: String?
    ) -> PokemonSpriteGroup? {
        let sprites = [
            sprite(id: "\(id)-front", title: "Front", value: front),
            sprite(id: "\(id)-back", title: "Back", value: back)
        ].compactMap { $0 }

        guard !sprites.isEmpty else { return nil }
        return PokemonSpriteGroup(id: id, title: title, sprites: sprites)
    }

    private func sprite(id: String, title: String, value: String?) -> PokemonSprite? {
        guard let value, let url = URL(string: value) else { return nil }
        return PokemonSprite(id: id, title: title, url: url)
    }

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case frontShiny = "front_shiny"
        case backDefault = "back_default"
        case backShiny = "back_shiny"
    }
}

struct PokemonSpriteGroup: Identifiable {
    let id: String
    let title: String
    let sprites: [PokemonSprite]
}

struct PokemonSprite: Identifiable {
    let id: String
    let title: String
    let url: URL
}

struct PokemonTypeSlot: Codable {
    let slot: Int
    let type: NamedAPIResource
}

struct PokemonAbilitySlot: Codable {
    let isHidden: Bool
    let ability: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case isHidden = "is_hidden"
        case ability
    }
}

struct PokemonStatSlot: Codable, Identifiable {
    let baseStat: Int
    let stat: NamedAPIResource

    var id: String { stat.name }

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}
