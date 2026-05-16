import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable { case pokemon, berries, items, favorites }
    
    @State private var selectedTab: Tab
    
    init(initialSelectedTab: Tab = .pokemon) {
        _selectedTab = State(initialValue: initialSelectedTab)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PokemonListView()
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label {
                    Text("Pokémon")
                } icon: {
                    Image("poke-ball")
                        .resizable()
                        .frame(width: Dimens.iconMedium, height: Dimens.iconMedium)
                }
            }
            .tag(Tab.pokemon)

            NavigationStack {
                BerriesListView()
                    .navigationTitle("Berries")
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label {
                    Text("Berries")
                } icon: {
                    Image("Bag_Sitrus_Berry_Sprite")
                        .resizable()
                        .frame(width: Dimens.iconMedium, height: Dimens.iconMedium)
                }
            }
            .tag(Tab.berries)

            NavigationStack {
                ItemsListView()
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label {
                    Text("Items")
                } icon: {
                    Image("leftovers")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Dimens.iconMedium, height: Dimens.iconMedium)
                }
            }
            .tag(Tab.items)

            NavigationStack {
                FavoritesView()
                    .navigationTitle("Favorites")
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
            .tag(Tab.favorites)
        }
    }
}


struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(FavoritesStore())
    }
}
