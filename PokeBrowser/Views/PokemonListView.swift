
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
            } else if viewModel.pokemons.isEmpty && !viewModel.isLoading && viewModel.searchText.isEmpty {
                Text("No Pokémon found")
                    .foregroundColor(.secondary)
            } else {
                let hasQuery = !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let results = viewModel.filteredPokemons

                if hasQuery && viewModel.isSearching {
                    VStack(spacing: 12) {
                        ProgressView("Searching…")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if hasQuery && results.isEmpty && !viewModel.isLoading && !viewModel.isSearching {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView("No matches", systemImage: "magnifyingglass", description: Text("Try a different search."))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No matches")
                                .font(.headline)
                            Text("Try a different search.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    List {
                        ForEach(results) { pokemon in
                            NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                                PokemonRowView(
                                    pokemon: pokemon,
                                    isFavorite: favorites.isFavorite(name: pokemon.name),
                                    onToggleFavorite: { favorites.toggle(name: pokemon.name) }
                                )
                            }
                            .task {
                                await viewModel.loadNextPageIfNeeded(currentPokemon: pokemon)
                            }
                        }

                        if viewModel.isLoading && viewModel.searchText.isEmpty && !viewModel.pokemons.isEmpty {
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
        }
        .navigationTitle("Pokémon Browser")
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search Pokémon")
        .modifier(SearchChangeModifier(searchText: $viewModel.searchText) {
            Task { await viewModel.searchIfNeeded() }
        })
        .onSubmit(of: .search) {
            Task { await viewModel.searchIfNeeded() }
        }
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
            if viewModel.isLoading && viewModel.searchText.isEmpty && viewModel.pokemons.isEmpty {
                ProgressView("Loading...")
            }
        }
    }
}

// Compatibility wrapper for onChange across iOS versions
fileprivate struct SearchChangeModifier: ViewModifier {
    @Binding var searchText: String
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: searchText) { _, _ in action() }
        } else {
            content.onChange(of: searchText) { _ in action() }
        }
    }
}
