//
//  ItemsListView.swift
//  PokeBrowser
//
//

import SwiftUI

struct ItemsListView: View {
    @StateObject private var viewModel: ItemsListViewModel
    private let disableAutoLoad: Bool

    init() {
        _viewModel = StateObject(wrappedValue: ItemsListViewModel())
        self.disableAutoLoad = false
    }

    init(viewModel: ItemsListViewModel, disableAutoLoad: Bool = false) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.disableAutoLoad = disableAutoLoad
    }

    var body: some View {
        Group {
            if let error = viewModel.error {
                VStack(spacing: 16) {
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task { await viewModel.loadItems(forceRefresh: true) }
                    }
                }
            } else if viewModel.items.isEmpty && !viewModel.isLoading {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("No items", systemImage: "bag.fill", description: Text("Try refreshing."))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "bag.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No items")
                            .font(.headline)
                        Text("Try refreshing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            ItemRowView(item: item)
                        }
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentItem: item)
                        }
                    }

                    if viewModel.isLoading && !viewModel.items.isEmpty {
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
        .navigationTitle("Items Documentation")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadItems(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
        .task { if !disableAutoLoad { await viewModel.loadItems() } }
        .overlay {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView("Loading...")
            }
        }
    }
}

private struct ItemRowView: View {
    let item: Item

    private var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/\(item.name).png")
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)

                if let spriteURL {
                    AsyncImage(url: spriteURL) { image in
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    } placeholder: {
                        Image(systemName: "bag")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.displayName)
                    .font(.headline)
                if let id = item.itemId {
                    Text("#\(id)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Items List - Sample") {
    let vm = ItemsListViewModel()
    vm.items = [
        Item(name: "master-ball", url: "https://pokeapi.co/api/v2/item/1/"),
        Item(name: "ultra-ball", url: "https://pokeapi.co/api/v2/item/2/"),
        Item(name: "potion", url: "https://pokeapi.co/api/v2/item/17/")
    ]
    return NavigationStack { ItemsListView(viewModel: vm, disableAutoLoad: true) }
}
