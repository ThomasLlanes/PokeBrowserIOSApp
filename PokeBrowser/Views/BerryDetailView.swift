// filepath: /Users/codigodelsur/Documents/Swift/PokeBrowser/PokeBrowser/Views/BerryDetailView.swift

import SwiftUI

struct BerryDetailView: View {
    let berry: Berry
    @StateObject private var viewModel: BerryDetailViewModel
    private let disableAutoLoad: Bool

    init(berry: Berry, disableAutoLoad: Bool = false) {
        self.berry = berry
        _viewModel = StateObject(wrappedValue: BerryDetailViewModel())
        self.disableAutoLoad = disableAutoLoad
    }

    init(berry: Berry, viewModel: BerryDetailViewModel, disableAutoLoad: Bool) {
        self.berry = berry
        _viewModel = StateObject(wrappedValue: viewModel)
        self.disableAutoLoad = disableAutoLoad
    }

    var body: some View {
        List {
            if let detail = viewModel.detail {
                Section(header: Text("Overview")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(detail.name.capitalized)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("ID")
                        Spacer()
                        Text("#\(detail.id)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Firmness")
                        Spacer()
                        Text(detail.firmness.name.capitalized)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Stats")) {
                    LabeledContent("Growth time", value: "\(detail.growthTime)")
                    LabeledContent("Max harvest", value: "\(detail.maxHarvest)")
                    LabeledContent("Size", value: "\(detail.size)")
                    LabeledContent("Smoothness", value: "\(detail.smoothness)")
                    LabeledContent("Soil dryness", value: "\(detail.soilDryness)")
                }

                if !detail.flavors.isEmpty {
                    Section(header: Text("Flavors")) {
                        ForEach(detail.flavors, id: \.flavor.name) { f in
                            HStack {
                                Text(f.flavor.name.capitalized)
                                Spacer()
                                Text("\(f.potency)")
                                    .foregroundStyle(.secondary)
                            }
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
                        ProgressView("Loading…")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(berry.name.capitalized)
        .task { if !disableAutoLoad { await viewModel.load(for: berry) } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.load(for: berry) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

#Preview("Berry Detail - Sample") {
    let berry = Berry(name: "oran", url: "https://pokeapi.co/api/v2/berry/1/")
    let vm = BerryDetailViewModel()
    vm.detail = BerryDetail(
        id: 1,
        name: "oran",
        growthTime: 3,
        maxHarvest: 5,
        size: 20,
        smoothness: 25,
        soilDryness: 15,
        firmness: NamedAPIResource(name: "soft", url: "https://pokeapi.co/api/v2/berry-firmness/2/"),
        flavors: [
            BerryFlavorMap(potency: 10, flavor: NamedAPIResource(name: "sweet", url: "https://pokeapi.co/api/v2/berry-flavor/4/")),
            BerryFlavorMap(potency: 5, flavor: NamedAPIResource(name: "sour", url: "https://pokeapi.co/api/v2/berry-flavor/5/"))
        ]
    )
    return NavigationStack { BerryDetailView(berry: berry, viewModel: vm, disableAutoLoad: true) }
}
