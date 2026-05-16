//
//  BerriesListView.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 31/10/25.
//

import SwiftUI

struct BerriesListView: View {
    @StateObject private var viewModel: BerriesListViewModel
    private let disableAutoLoad: Bool

    init() {
        _viewModel = StateObject(wrappedValue: BerriesListViewModel())
        self.disableAutoLoad = false
    }

    init(viewModel: BerriesListViewModel, disableAutoLoad: Bool = false) {
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
                        Task { await viewModel.loadBerries(forceRefresh: true) }
                    }
                }
            } else if viewModel.berries.isEmpty && !viewModel.isLoading {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("No berries", systemImage: "leaf.fill", description: Text("Try refreshing."))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No berries")
                            .font(.headline)
                        Text("Try refreshing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                List {
                    ForEach(viewModel.berries) { berry in
                        NavigationLink(destination: BerryDetailView(berry: berry, disableAutoLoad: false)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(berry.name.displayName)
                                    .font(.headline)
                                if let id = berry.berryId {
                                    Text("#\(id)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentBerry: berry)
                        }
                    }

                    if viewModel.isLoading && !viewModel.berries.isEmpty {
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
        .navigationTitle("Berries")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadBerries(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
        .task { if !disableAutoLoad { await viewModel.loadBerries() } }
        .overlay {
            if viewModel.isLoading && viewModel.berries.isEmpty {
                ProgressView("Loading...")
            }
        }
    }
}

#Preview("Berries List - Sample") {
    let vm = BerriesListViewModel()
    vm.berries = [
        Berry(name: "oran", url: "https://pokeapi.co/api/v2/berry/1/"),
        Berry(name: "sitrus", url: "https://pokeapi.co/api/v2/berry/2/"),
        Berry(name: "pecha", url: "https://pokeapi.co/api/v2/berry/3/")
    ]
    vm.isLoading = false
    vm.error = nil
    return NavigationStack { BerriesListView(viewModel: vm, disableAutoLoad: true) }
}
