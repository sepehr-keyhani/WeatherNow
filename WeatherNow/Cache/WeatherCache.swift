//
//  WeatherCache.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import Foundation

final class WeatherCache {
    private struct Entry { let value: Weather; let expiry: Date }
    private var storage: [String: Entry] = [:]
    private let timeToLive: TimeInterval

    init(timeToLive: TimeInterval = 10 * 60) { // 10 minutes
        self.timeToLive = timeToLive
    }

    func get(for city: String) -> Weather? {
        guard let entry = storage[city.lowercased()] else { return nil }
        if Date() < entry.expiry { return entry.value }
        storage[city.lowercased()] = nil
        return nil
    }

    func set(_ weather: Weather, for city: String) {
        storage[city.lowercased()] = Entry(value: weather, expiry: Date().addingTimeInterval(timeToLive))
    }
}


