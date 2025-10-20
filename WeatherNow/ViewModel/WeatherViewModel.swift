//
//  WeatherViewModel.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//


import Foundation

@MainActor
final class WeatherViewModel {
    struct State: Equatable {
        var isLoading: Bool = false
        var weather: Weather? = nil
        var errorMessage: String? = nil
        var places: [Place] = []
        var favorites: [Place] = []
        var showingFavorites: Bool = true
        var headerTitle: String? = nil
    }

    private(set) var state: State = State() { didSet { onChange?(state) } }
    var onChange: ((State) -> Void)?

    private let service: WeatherServicing
    private let cache: WeatherCache
    private let favoritesStore = FavoritesStore()
    private var favoriteWeathers: [Place: Weather] = [:]

    init(service: WeatherServicing, cache: WeatherCache) {
        self.service = service
        self.cache = cache
        self.state.favorites = favoritesStore.load()
        Task { await refreshFavoriteWeathers() }
    }

    func search(city: String) async {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let cached = cache.get(for: trimmed) {
            state.weather = cached
            state.errorMessage = nil
            return
        }

        state.isLoading = true
        state.errorMessage = nil
        do {
            let result = try await service.fetchWeather(for: trimmed)
            state.weather = result
            cache.set(result, for: trimmed)
            state.headerTitle = result.city.isEmpty ? trimmed : result.city
        } catch {
            state.weather = nil
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        state.isLoading = false
    }

    func loadByCoordinates(lat: Double, lon: Double) async {
        state.isLoading = true
        state.errorMessage = nil
        do {
            let result = try await service.fetchWeather(lat: lat, lon: lon)
            state.weather = result
            // ensure city label appears on initial load
            state.places = []
            state.showingFavorites = false
            state.headerTitle = result.city
        } catch {
            state.weather = nil
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        state.isLoading = false
        await refreshFavoriteWeathers()
    }

    func liveSearchPlaces(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            state.places = []
            state.showingFavorites = true
            onChange?(state)
            return
        }
        state.showingFavorites = false
        do {
            let results = try await service.searchPlaces(query: trimmed)
            // Local word-match filter to ensure each word is found somewhere in displayName
            let words = trimmed.lowercased().split(separator: " ")
            let filtered = results.filter { place in
                let target = place.displayName.lowercased()
                for w in words { if !target.contains(w) { return false } }
                return true
            }
            state.places = filtered
            state.errorMessage = nil
        } catch {
            state.places = []
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func toggleFavorite(_ place: Place) {
        if let idx = state.favorites.firstIndex(of: place) {
            state.favorites.remove(at: idx)
        } else {
            state.favorites.insert(place, at: 0)
        }
        favoritesStore.save(state.favorites)
        onChange?(state)
        Task { await refreshFavoriteWeathers() }
    }

    func toggleFavoriteForCurrentWeather() {
        guard let w = state.weather else { return }
        let components = w.city.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: true)
        let name = components.first.map(String.init) ?? w.city
        let country = components.count > 1 ? String(components[1]).trimmingCharacters(in: .whitespaces) : nil
        let place = Place(name: name, country: country, latitude: w.latitude ?? 0, longitude: w.longitude ?? 0)
        toggleFavorite(place)
    }

    func isCurrentWeatherFavorite() -> Bool {
        guard let w = state.weather else { return false }
        let components = w.city.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: true)
        let name = components.first.map(String.init) ?? w.city
        // Prefer name match; coordinates may differ slightly between APIs
        return state.favorites.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }

    func weatherForFavorite(_ place: Place) -> Weather? { favoriteWeathers[place] }

    func refreshFavoriteWeathers() async {
        for place in state.favorites {
            if favoriteWeathers[place] != nil { continue }
            do {
                let w = try await service.fetchWeather(lat: place.latitude, lon: place.longitude)
                favoriteWeathers[place] = w
                onChange?(state)
            } catch {
                // ignore per-place load errors
            }
        }
    }

    func selectPlace(_ place: Place) async {
        state.showingFavorites = false
        state.isLoading = true
        do {
            let weather = try await service.fetchWeather(lat: place.latitude, lon: place.longitude)
            state.weather = weather
            state.errorMessage = nil
            state.headerTitle = place.displayName
        } catch {
            state.weather = nil
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        state.isLoading = false
        // hide results list after selection
        state.places = []
        onChange?(state)
    }
}


