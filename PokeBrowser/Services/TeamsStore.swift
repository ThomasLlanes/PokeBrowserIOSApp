//
//  TeamsStore.swift
//  PokeBrowser
//

import Foundation
import Combine

final class TeamsStore: ObservableObject {
    @Published private(set) var teams: [PokemonTeam]

    private let defaults: UserDefaults
    private let defaultsKey = "pokemonTeams"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([PokemonTeam].self, from: data) {
            teams = decoded
        } else {
            teams = []
        }
    }

    func add(_ team: PokemonTeam) {
        teams.insert(team, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            teams.remove(at: index)
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(teams) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
