//
//  ItemDetailView.swift
//  PokeBrowser
//
//

import SwiftUI

struct ItemDetailView: View {
    let item: Item
    @StateObject private var viewModel: ItemDetailViewModel
    private let disableAutoLoad: Bool

    init(item: Item, disableAutoLoad: Bool = false) {
        self.item = item
        _viewModel = StateObject(wrappedValue: ItemDetailViewModel())
        self.disableAutoLoad = disableAutoLoad
    }

    init(item: Item, viewModel: ItemDetailViewModel, disableAutoLoad: Bool) {
        self.item = item
        _viewModel = StateObject(wrappedValue: viewModel)
        self.disableAutoLoad = disableAutoLoad
    }

    var body: some View {
        List {
            if let detail = viewModel.detail {
                Section {
                    HStack {
                        Spacer()
                        SpriteGalleryView(sprites: detail.sprites.sortedSprites)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("Overview")) {
                    LabeledContent("Name", value: detail.name.displayName)
                    LabeledContent("ID", value: "#\(detail.id)")
                    LabeledContent("Category", value: detail.category.name.displayName)
                    LabeledContent("Cost", value: "\(detail.cost)")
                    if let flingPower = detail.flingPower {
                        LabeledContent("Fling power", value: "\(flingPower)")
                    }
                }

                if let effect = detail.displayEffect {
                    Section(header: Text("Effect")) {
                        Text(effect.cleanedPokeAPIText)
                    }
                }

                if let flavorText = detail.displayFlavorText {
                    Section(header: Text("Flavor Text")) {
                        Text(flavorText.cleanedPokeAPIText)
                    }
                }

                if !detail.attributes.isEmpty {
                    Section(header: Text("Attributes")) {
                        ForEach(detail.attributes, id: \.name) { attribute in
                            Text(attribute.name.displayName)
                        }
                    }
                }
            } else if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading...")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(item.name.displayName)
        .task { if !disableAutoLoad { await viewModel.load(for: item) } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.load(for: item) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
    }
}

private struct SpriteGalleryView: View {
    let sprites: [(name: String, url: URL)]

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(sprites, id: \.name) { sprite in
                VStack(spacing: 8) {
                    AsyncImage(url: sprite.url) { image in
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 72, height: 72)
                    .accessibilityLabel(sprite.name.displayName)

                    if sprites.count > 1 {
                        Text(sprite.name.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private extension String {
    var cleanedPokeAPIText: String {
        replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{0C}", with: " ")
    }
}

#Preview("Item Detail - Sample") {
    let item = Item(name: "master-ball", url: "https://pokeapi.co/api/v2/item/1/")
    let vm = ItemDetailViewModel()
    vm.detail = ItemDetail(
        id: 1,
        name: "master-ball",
        cost: 0,
        flingPower: nil,
        category: NamedAPIResource(name: "standard-balls", url: "https://pokeapi.co/api/v2/item-category/34/"),
        sprites: ItemSprites(values: [
            "default": URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/master-ball.png")!
        ]),
        effectEntries: [
            VerboseEffect(
                effect: "Used in battle. Catches a wild Pokemon without fail.",
                shortEffect: "Catches a wild Pokemon every time.",
                language: NamedAPIResource(name: "en", url: "https://pokeapi.co/api/v2/language/9/")
            )
        ],
        flavorTextEntries: [],
        attributes: []
    )
    return NavigationStack { ItemDetailView(item: item, viewModel: vm, disableAutoLoad: true) }
}
