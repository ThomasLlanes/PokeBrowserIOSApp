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

private struct TeamDetailView: View {
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

private struct TeamPokemonSpriteWithItem: View {
    let pokemon: TeamPokemon
    let item: TeamItem?
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PokemonSpriteTile(url: pokemon.spriteURL, size: size)

            if let item {
                HeldItemBadge(item: item)
                    .offset(x: 3, y: 3)
            }
        }
        .frame(width: size + 6, height: size + 6)
    }
}

private struct HeldItemBadge: View {
    let item: TeamItem

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 26, height: 26)
                .shadow(radius: 1)

            if let url = item.spriteURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                } placeholder: {
                    Image(systemName: "bag")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 20, height: 20)
            }
        }
        .accessibilityLabel(item.name.displayName)
    }
}

private struct TeamBuilderView: View {
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

private struct PokemonSpriteTile: View {
    let url: URL?
    let size: CGFloat
    var fallbackSystemImage = "questionmark"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: size, height: size)

            if let url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                } placeholder: {
                    ProgressView().scaleEffect(0.7)
                }
                .frame(width: size - 8, height: size - 8)
            } else {
                Image(systemName: fallbackSystemImage)
                    .foregroundStyle(.secondary)
            }
        }
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

#Preview("Teams") {
    NavigationStack {
        TeamsView()
    }
}
