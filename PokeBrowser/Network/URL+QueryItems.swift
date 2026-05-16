//
//  URL+QueryItems.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 14/05/26.
//

import Foundation

extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? self
    }
}

