//
//  PokemonCache.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 30/10/25.
//

import Foundation

final class PokemonCache {
    private let fileName = "pokemon_list.json"
    private var fileURL: URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent(fileName)
    }
    
    func load() -> [Pokemon]? {
        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PokeAPIListResponse<Pokemon>.self, from: data)
            return decoded.results
        } catch {
            print("⚠️ Failed to load cached Pokemon list: \(error)")
            return nil
        }
    }
    
    func save(_ list: [Pokemon]) {
        do {
            let data = try JSONEncoder().encode(PokeAPIListResponse(results: list))
            try data.write(to: fileURL, options: [.atomic])
            print("💾 Cached \(list.count) Pokémon to \(fileURL.lastPathComponent)")
        } catch {
            print("⚠️ Failed to cache Pokemon list: \(error)")
        }
    }
}
