//
//  TeamBuilderView.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 16/5/26.
//

import SwiftUI

struct TeamBuilderView: View {
    @ObservedObject var store: TeamsStore
    @StateObject private var viewModel = TeamsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var itemSlot: PokemonTeamSlot?

    var body: some View {
        List {
            Section {
                TextField("Team name", text: $viewModel.teamName)
                    .textInputAutocapitalization(.words)
            }

            if !viewModel.selectedSlots.isEmpty {
                Section("Selected Pokémon") {
                    ForEach(viewModel.selectedSlots) { slot in
                        SelectedTeamSlotRow(slot: slot) {
                            itemSlot = slot
                        }
                    }
                }
            }

            Section {
                ForEach(viewModel.pokemon) { pokemon in
                    Button {
                        viewModel.togglePokemon(pokemon)
                    } label: {
                        PokemonSelectionRow(
                            pokemon: pokemon,
                            isSelected: viewModel.isSelected(pokemon),
                            isDisabled: viewModel.selectedSlots.count == 6 && !viewModel.isSelected(pokemon)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.selectedSlots.count == 6 && !viewModel.isSelected(pokemon))
                    .task {
                        await viewModel.loadNextPokemonPageIfNeeded(currentPokemon: pokemon)
                    }
                }

                if viewModel.isLoadingPokemon && !viewModel.pokemon.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } header: {
                Text("Choose up to 6 Pokémon")
            } footer: {
                Text("\(viewModel.selectedSlots.count)/6 selected")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("New Team")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done", action: saveTeam)
                    .disabled(!viewModel.canSaveTeam)
            }
        }
        .overlay {
            if viewModel.isLoadingPokemon && viewModel.pokemon.isEmpty {
                ProgressView("Loading Pokémon...")
            } else if let error = viewModel.error, viewModel.pokemon.isEmpty {
                ContentUnavailableFallback(title: "Could not load Pokémon", message: error)
            }
        }
        .sheet(item: $itemSlot) { slot in
            NavigationStack {
                HeldItemSelectionView(viewModel: viewModel, slot: slot)
            }
        }
        .task {
            await viewModel.loadPokemon()
            await viewModel.loadItems()
        }
    }

    private func saveTeam() {
        guard viewModel.canSaveTeam else { return }
        store.add(viewModel.makeTeam())
        dismiss()
    }
}

private struct PokemonSelectionRow: View {
    let pokemon: Pokemon
    let isSelected: Bool
    let isDisabled: Bool

    private var spriteURL: URL? {
        guard let id = pokemon.pokemonId else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }

    var body: some View {
        HStack(spacing: 12) {
            PokemonSpriteTile(url: spriteURL, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(pokemon.name.displayName)
                    .font(.headline)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                if let id = pokemon.pokemonId {
                    Text("#\(id)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .green : .secondary)
                .imageScale(.large)
        }
        .padding(.vertical, 4)
    }
}

private struct SelectedTeamSlotRow: View {
    let slot: PokemonTeamSlot
    let onPickItem: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TeamPokemonSpriteWithItem(pokemon: slot.pokemon, item: slot.heldItem, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(slot.pokemon.name.displayName)
                    .font(.headline)

                Button(action: onPickItem) {
                    HStack(spacing: 6) {
                        if let item = slot.heldItem {
                            HeldItemBadge(item: item)
                        } else {
                            Image(systemName: "bag")
                        }
                        Text(slot.heldItem?.name.displayName ?? "No item")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(action: onPickItem) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change held item")
        }
        .padding(.vertical, 4)
    }
}

private struct HeldItemSelectionView: View {
    @ObservedObject var viewModel: TeamsViewModel
    let slot: PokemonTeamSlot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button {
                viewModel.setHeldItem(nil, for: slot)
                dismiss()
            } label: {
                Label("No item", systemImage: "xmark.circle")
            }

            ForEach(viewModel.items) { item in
                Button {
                    viewModel.setHeldItem(item, for: slot)
                    dismiss()
                } label: {
                    ItemSelectionRow(item: item, isSelected: slot.heldItem?.name == item.name)
                }
                .buttonStyle(.plain)
                .task {
                    await viewModel.loadNextItemPageIfNeeded(currentItem: item)
                }
            }

            if viewModel.isLoadingItems && !viewModel.items.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle("Held Item")
        .overlay {
            if viewModel.isLoadingItems && viewModel.items.isEmpty {
                ProgressView("Loading items...")
            }
        }
    }
}

private struct ItemSelectionRow: View {
    let item: Item
    let isSelected: Bool

    private var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/\(item.name).png")
    }

    var body: some View {
        HStack(spacing: 12) {
            PokemonSpriteTile(url: spriteURL, size: 44, fallbackSystemImage: "bag")

            Text(item.name.displayName)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ContentUnavailableFallback: View {
    let title: String
    let message: String

    var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(title, systemImage: "exclamationmark.triangle", description: Text(message))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
