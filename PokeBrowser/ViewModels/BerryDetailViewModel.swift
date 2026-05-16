//
//  BerryDetailViewModel.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 31/10/25.
//

import Foundation
import Combine

@MainActor
final class BerryDetailViewModel: ObservableObject {
    @Published var detail: BerryDetail?
    @Published var isLoading = false
    @Published var error: String?

    private let service: BerryServing

    init(service: BerryServing? = nil) {
        self.service = service ?? BerryService()
    }

    func load(for berry: Berry) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let key = berry.berryId.map(String.init) ?? berry.name
            let d = try await service.fetchBerryDetail(idOrName: key)
            self.detail = d
        } catch {
            self.error = error.localizedDescription
        }
    }
}
