// filepath: /Users/codigodelsur/Documents/Swift/PokeBrowser/PokeBrowser/Services/BerryCache.swift
//
//  BerryCache.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 31/10/25.
//

import Foundation

final class BerryCache {
    private let fileName = "berry_list.json"
    private var fileURL: URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent(fileName)
    }

    func load() -> [Berry]? {
        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PokeAPIListResponse<Berry>.self, from: data)
            return decoded.results
        } catch {
            print("⚠️ Failed to load cached berry list: \(error)")
            return nil
        }
    }

    func save(_ list: [Berry]) {
        do {
            let data = try JSONEncoder().encode(PokeAPIListResponse(results: list))
            try data.write(to: fileURL, options: [.atomic])
            print("💾 Cached \(list.count) berries to \(fileURL.lastPathComponent)")
        } catch {
            print("⚠️ Failed to cache berry list: \(error)")
        }
    }
}
