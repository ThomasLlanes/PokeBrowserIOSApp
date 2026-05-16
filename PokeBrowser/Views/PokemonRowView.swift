//
//  PokemonRowView.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 30/10/25.
//

import SwiftUI

struct PokemonRowView: View {
    let pokemon: Pokemon
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    private var spriteURL: URL? {
        guard let id = pokemon.pokemonId else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 56, height: 56)
                if let url = spriteURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView().scaleEffect(0.8)
                    }
                    .frame(width: 48, height: 48)
                } else {
                    Image(systemName: "questionmark")
                        .foregroundColor(.secondary)
                        .frame(width: 48, height: 48)
                }
            }
            
            Text(pokemon.name.capitalized)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding(.vertical, 6)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PokemonRowView(
        pokemon: Pokemon(name: "pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/"),
        isFavorite: true,
        onToggleFavorite: {}
    )
    .padding()
}
