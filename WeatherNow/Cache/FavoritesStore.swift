//
//  FavoritesStore.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import Foundation

final class FavoritesStore {
    private let key = "favorite_places"

    func load() -> [Place] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Place].self, from: data)) ?? []
    }

    func save(_ places: [Place]) {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}


