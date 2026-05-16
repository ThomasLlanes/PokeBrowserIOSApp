//
//  TeamSpriteViews.swift
//  PokeBrowser
//

import SwiftUI

struct TeamPokemonSpriteWithItem: View {
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

struct HeldItemBadge: View {
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

struct PokemonSpriteTile: View {
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
