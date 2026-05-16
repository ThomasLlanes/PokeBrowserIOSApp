//
//  APIEndpoint.swift
//  PokeBrowser
//
//  Created by Codex on 14/05/26.
//

import Foundation

enum APIEndpoint {
    case pokemonList(limit: Int, offset: Int)
    case pokemonDetail(idOrName: String)
    case berryList(limit: Int)
    case berryDetail(idOrName: String)

    private static let baseURL = URL(string: "https://pokeapi.co/api/v2")!

    var url: URL {
        switch self {
        case .pokemonList(let limit, let offset):
            return Self.baseURL
                .appending(path: "pokemon")
                .appending(queryItems: [
                    .init(name: "limit", value: String(limit)),
                    .init(name: "offset", value: String(offset))
                ])
        case .pokemonDetail(let idOrName):
            return Self.baseURL.appending(path: "pokemon/\(idOrName)")
        case .berryList(let limit):
            return Self.baseURL
                .appending(path: "berry")
                .appending(queryItems: [.init(name: "limit", value: String(limit))])
        case .berryDetail(let idOrName):
            return Self.baseURL.appending(path: "berry/\(idOrName)")
        }
    }
}
