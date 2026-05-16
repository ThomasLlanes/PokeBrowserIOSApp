// filepath: /Users/codigodelsur/Documents/Swift/PokeBrowser/PokeBrowser/Models/Berry.swift
//
//  Berry.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 31/10/25.
//

import Foundation

struct Berry: Codable, Identifiable {
    let name: String
    let url: String

    var id: String { name }

    // Extract numeric ID from the API URL, e.g. "https://pokeapi.co/api/v2/berry/1/" -> 1
    var berryId: Int? {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = trimmed.split(separator: "/").last else { return nil }
        return Int(last)
    }
}
