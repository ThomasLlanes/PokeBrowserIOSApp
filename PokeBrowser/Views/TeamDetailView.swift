//
//  TeamDetailView.swift
//  PokeBrowser
//

import SwiftUI

struct TeamDetailView: View {
    let team: PokemonTeam

    var body: some View {
        List {
            Section {
                ForEach(team.slots) { slot in
                    TeamDetailSlotRow(slot: slot)
                }
            } header: {
                Text("\(team.slots.count)/6 Pokémon")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(team.name)
    }
}

private struct TeamDetailSlotRow: View {
    let slot: PokemonTeamSlot

    var body: some View {
        HStack(spacing: 12) {
            TeamPokemonSpriteWithItem(pokemon: slot.pokemon, item: slot.heldItem, size: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(slot.pokemon.name.displayName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let item = slot.heldItem {
                        HeldItemBadge(item: item)
                        Text(item.name.displayName)
                    } else {
                        Image(systemName: "bag")
                            .foregroundStyle(.secondary)
                        Text("No item")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
