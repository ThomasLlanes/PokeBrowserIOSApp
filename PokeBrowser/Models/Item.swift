//
//  Item.swift
//  PokeBrowser
//
//

import Foundation

struct Item: Codable, Identifiable {
    let name: String
    let url: String

    var id: String { name }

    var itemId: Int? {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = trimmed.split(separator: "/").last else { return nil }
        return Int(last)
    }
}

struct ItemDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let cost: Int
    let flingPower: Int?
    let category: NamedAPIResource
    let sprites: ItemSprites
    let effectEntries: [VerboseEffect]
    let flavorTextEntries: [VersionGroupFlavorText]
    let attributes: [NamedAPIResource]

    var displayEffect: String? {
        effectEntries.first(where: { $0.language.name == "en" })?.shortEffect
            ?? effectEntries.first(where: { $0.language.name == "en" })?.effect
    }

    var displayFlavorText: String? {
        flavorTextEntries.first(where: { $0.language.name == "en" })?.text
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cost
        case flingPower = "fling_power"
        case category
        case sprites
        case effectEntries = "effect_entries"
        case flavorTextEntries = "flavor_text_entries"
        case attributes
    }
}

struct ItemSprites: Codable {
    let values: [String: URL]

    var primarySpriteURL: URL? {
        values["default"] ?? sortedSprites.first?.url
    }

    var sortedSprites: [(name: String, url: URL)] {
        values
            .map { (name: $0.key, url: $0.value) }
            .sorted { lhs, rhs in
                if lhs.name == "default" { return true }
                if rhs.name == "default" { return false }
                return lhs.name < rhs.name
            }
    }

    init(values: [String: URL]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decodedValues: [String: URL] = [:]

        for key in container.allKeys {
            guard let urlString = try container.decodeIfPresent(String.self, forKey: key),
                  let url = URL(string: urlString) else {
                continue
            }
            decodedValues[key.stringValue] = url
        }

        values = decodedValues
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)

        for (key, url) in values {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            try container.encode(url.absoluteString, forKey: codingKey)
        }
    }
}

struct VerboseEffect: Codable {
    let effect: String
    let shortEffect: String
    let language: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case effect
        case shortEffect = "short_effect"
        case language
    }
}

struct VersionGroupFlavorText: Codable {
    let text: String
    let language: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case text = "text"
        case language
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}
