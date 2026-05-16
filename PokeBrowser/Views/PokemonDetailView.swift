//
//  PokemonDetailView.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 28/10/25.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: Pokemon
    @StateObject private var viewModel: PokemonDetailViewModel
    @EnvironmentObject private var favorites: FavoritesStore
    private let disableAutoLoad: Bool

    init(pokemon: Pokemon, disableAutoLoad: Bool = false) {
        self.pokemon = pokemon
        _viewModel = StateObject(wrappedValue: PokemonDetailViewModel())
        self.disableAutoLoad = disableAutoLoad
    }

    init(pokemon: Pokemon, viewModel: PokemonDetailViewModel, disableAutoLoad: Bool) {
        self.pokemon = pokemon
        _viewModel = StateObject(wrappedValue: viewModel)
        self.disableAutoLoad = disableAutoLoad
    }

    var body: some View {
        List {
            if let detail = viewModel.detail {
                Section {
                    HStack {
                        Spacer()
                        PokemonSpriteGalleryView(sprites: detail.sprites.displaySprites)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("Overview")) {
                    LabeledContent("Name", value: detail.name.displayName)
                    LabeledContent("ID", value: "#\(detail.id)")
                    LabeledContent("Height", value: "\(detail.height)")
                    LabeledContent("Weight", value: "\(detail.weight)")
                    if let baseExperience = detail.baseExperience {
                        LabeledContent("Base experience", value: "\(baseExperience)")
                    }
                }

                Section(header: Text("Types")) {
                    ForEach(detail.types.sorted(by: { $0.slot < $1.slot }), id: \.slot) { typeSlot in
                        Text(typeSlot.type.name.displayName)
                    }
                }

                Section(header: Text("Abilities")) {
                    ForEach(detail.abilities, id: \.ability.name) { abilitySlot in
                        LabeledContent(
                            abilitySlot.ability.name.displayName,
                            value: abilitySlot.isHidden ? "Hidden" : "Standard"
                        )
                    }
                }

                Section(header: Text("Stats")) {
                    ForEach(detail.stats) { stat in
                        LabeledContent(stat.stat.name.displayName, value: "\(stat.baseStat)")
                    }
                }
            } else if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading...")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(pokemon.name.displayName)
        .task { if !disableAutoLoad { await viewModel.load(for: pokemon) } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    favorites.toggle(name: pokemon.name)
                } label: {
                    Image(systemName: favorites.isFavorite(name: pokemon.name) ? "star.fill" : "star")
                        .foregroundStyle(favorites.isFavorite(name: pokemon.name) ? .yellow : .primary)
                }
                .accessibilityLabel(favorites.isFavorite(name: pokemon.name) ? "Remove from favorites" : "Add to favorites")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.load(for: pokemon) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
    }
}

private struct PokemonSpriteGalleryView: View {
    let sprites: [(name: String, url: URL)]

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(sprites, id: \.name) { sprite in
                VStack(spacing: 8) {
                    AsyncImage(url: sprite.url) { image in
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 88, height: 88)
                    .accessibilityLabel(sprite.name)

                    if sprites.count > 1 {
                        Text(sprite.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PokemonDetailView(pokemon: Pokemon(name: "pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/"))
            .environmentObject(FavoritesStore())
    }
}
