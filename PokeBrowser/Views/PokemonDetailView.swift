//
//  PokemonDetailView.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 28/10/25.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: Pokemon
    @EnvironmentObject private var favorites: FavoritesStore

    private var spriteURL: URL? {
        guard let id = pokemon.pokemonId else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                if let url = spriteURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 180)
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary)
                        .frame(height: 100)
                }
            }
            
            Text(pokemon.name.capitalized)
                .font(.largeTitle.bold())
                .padding(.top, 4)
            
            if let id = pokemon.pokemonId {
                Text("#\(id)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(pokemon.name.capitalized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    favorites.toggle(name: pokemon.name)
                } label: {
                    Image(systemName: favorites.isFavorite(name: pokemon.name) ? "star.fill" : "star")
                        .foregroundColor(favorites.isFavorite(name: pokemon.name) ? .yellow : .primary)
                }
                .accessibilityLabel(favorites.isFavorite(name: pokemon.name) ? "Remove from favorites" : "Add to favorites")
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
