//
//  String+DisplayName.swift
//  PokeBrowser
//
//

import Foundation

extension String {
    var displayName: String {
        split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
