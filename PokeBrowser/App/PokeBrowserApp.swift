//
//  PokeBrowserApp.swift
//  PokeBrowser
//
//  Created by CodigoDelSur on 31/10/25.
//

// swift
import SwiftUI

@main
struct PokeBrowserApp: App {
    @StateObject private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(favorites)
        }
    }
}

struct PokeBrowserApp_Previews: PreviewProvider {
    static var previews: some View {
       RootTabView()
            .environmentObject(FavoritesStore())
    }
}
