//
//  ContentView.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 28/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                PokemonListView()
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Pokémon", systemImage: "smallcircle.filled.circle.fill")
            }
            
            NavigationStack {
                BerriesListView()
                    .navigationTitle("Berries")
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Berries", systemImage: "leaf.fill")
            }

            NavigationStack {
                ItemsListView()
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Items Docs", systemImage: "bag.fill")
            }
            
            NavigationStack {
                FavoritesView()
                    .navigationTitle("Favorites")
                    .toolbar(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FavoritesStore())
}
