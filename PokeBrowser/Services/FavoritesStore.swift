//
//  FavoritesStore.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 30/10/25.
//

import Foundation
import Combine

final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: Set<String>
    
    private let defaultsKey = "favoritePokemonNames"
    
    init() {
        if let saved = UserDefaults.standard.array(forKey: defaultsKey) as? [String] {
            self.favorites = Set(saved)
        } else {
            self.favorites = []
        }
    }
    
    func isFavorite(name: String) -> Bool {
        favorites.contains(name.lowercased())
    }
    
    func toggle(name: String) {
        let key = name.lowercased()
        if favorites.contains(key) {
            favorites.remove(key)
        } else {
            favorites.insert(key)
        }
        persist()
    }
    
    private func persist() {
        UserDefaults.standard.set(Array(favorites), forKey: defaultsKey)
    }
}
