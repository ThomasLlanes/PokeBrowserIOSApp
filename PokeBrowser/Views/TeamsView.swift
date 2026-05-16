//
//  TeamsView.swift
//  PokeBrowser
//

import SwiftUI

struct TeamsView: View {
    @StateObject private var store: TeamsStore

    init(store: TeamsStore = TeamsStore()) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        List {
            NavigationLink {
                TeamBuilderView(store: store)
            } label: {
                Label("New Team", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 8)
            }

            if store.teams.isEmpty {
                Text("Your teams will appear here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.teams) { team in
                    NavigationLink {
                        TeamDetailView(team: team)
                    } label: {
                        TeamCardView(team: team)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: store.delete)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Teams")
    }
}

private struct TeamCardView: View {
    let team: PokemonTeam

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(team.name)
                .font(.headline)
                .lineLimit(1)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(team.slots) { slot in
                    TeamSlotSummaryView(slot: slot)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct TeamSlotSummaryView: View {
    let slot: PokemonTeamSlot

    var body: some View {
        TeamPokemonSpriteWithItem(pokemon: slot.pokemon, item: slot.heldItem, size: 58)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let item = slot.heldItem {
            return "\(slot.pokemon.name.displayName) holding \(item.name.displayName)"
        }
        return "\(slot.pokemon.name.displayName) holding no item"
    }
}

#Preview("Teams") {
    NavigationStack {
        TeamsView()
    }
}
