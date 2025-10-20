//
//  Place.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import Foundation

struct Place: Codable, Hashable, Equatable {
    let name: String
    let country: String?
    let latitude: Double
    let longitude: Double

    var displayName: String {
        [name, country].compactMap { $0 }.joined(separator: ", ")
    }
}


