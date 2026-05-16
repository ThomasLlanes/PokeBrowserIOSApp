//
//  Pokemon.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 28/10/25.
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
}
