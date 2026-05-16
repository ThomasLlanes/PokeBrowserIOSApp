
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore

    private var sortedFavorites: [String] {
        Array(favorites.favorites).sorted()
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
                    ForEach(sortedFavorites, id: \.self) { name in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(name.capitalized)
                        }
                        .accessibilityElement(children: .combine)
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
        for index in offsets { favorites.toggle(name: sortedFavorites[index]) }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
            .environmentObject(FavoritesStore())
    }
}
