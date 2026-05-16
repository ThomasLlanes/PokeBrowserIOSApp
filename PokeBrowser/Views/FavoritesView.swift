
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore

    private var sortedFavorites: [FavoritePokemon] {
        favorites.favorites.sorted { $0.name < $1.name }
    }

    var body: some View {
        Group {
            if sortedFavorites.isEmpty {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("No favorites yet", systemImage: "star", description: Text("Mark Pokémon with the star to see them here."))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No favorites yet")
                            .font(.headline)
                        Text("Mark Pokémon with the star to see them here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
            } else {
                List {
                    ForEach(sortedFavorites) { favorite in
                        NavigationLink(destination: PokemonDetailView(pokemon: favorite.pokemon)) {
                            FavoritePokemonRow(favorite: favorite)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Favorites")
        .toolbar { EditButton() }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            favorites.remove(sortedFavorites[index])
        }
    }
}

private struct FavoritePokemonRow: View {
    let favorite: FavoritePokemon

    private var imageURL: URL? {
        guard let imageURL = favorite.imageURL else { return nil }
        return URL(string: imageURL)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 56, height: 56)

                if let imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    } placeholder: {
                        ProgressView().scaleEffect(0.8)
                    }
                    .frame(width: 48, height: 48)
                } else {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .frame(width: 48, height: 48)
                }
            }

            Text(favorite.name.displayName)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
            .environmentObject(FavoritesStore())
    }
}
