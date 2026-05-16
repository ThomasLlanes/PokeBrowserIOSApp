
import SwiftUI

struct PokemonListView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    @EnvironmentObject private var favorites: FavoritesStore

    init() {
        print("🚀 PokemonListView initialized")
    }

    var body: some View {
        Group {
            if let error = viewModel.error {
                VStack(spacing: 16) {
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task { await viewModel.loadPokemon(forceRefresh: true) }
                    }
                }
            } else if viewModel.pokemons.isEmpty && !viewModel.isLoading {
                Text("No Pokémon found")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(viewModel.pokemons) { pokemon in
                        NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                            PokemonRowView(
                                pokemon: pokemon,
                                isFavorite: favorites.isFavorite(name: pokemon.name),
                                onToggleFavorite: {
                                    favorites.toggle(pokemon: pokemon)
                                }
                            )
                        }
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentPokemon: pokemon)
                        }
                    }

                    if viewModel.isLoading && !viewModel.pokemons.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Pokémon Browser")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadPokemon(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
        .task { await viewModel.loadPokemon() }
        .overlay {
            if viewModel.isLoading && viewModel.pokemons.isEmpty {
                ProgressView("Loading...")
            }
        }
    }
}
