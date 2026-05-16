//
//  BerryDetail.swift
//  PokeBrowser
//
//  Created by Thomas Llanes on 31/10/25.
//

import Foundation

struct NamedAPIResource: Codable {
    let name: String
    let url: String
}

struct BerryFlavorMap: Codable {
    let potency: Int
    let flavor: NamedAPIResource
}

struct BerryDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let growthTime: Int
    let maxHarvest: Int
    let size: Int
    let smoothness: Int
    let soilDryness: Int
    let firmness: NamedAPIResource
    let flavors: [BerryFlavorMap]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case growthTime = "growth_time"
        case maxHarvest = "max_harvest"
        case size
        case smoothness
        case soilDryness = "soil_dryness"
        case firmness
        case flavors
    }
}
