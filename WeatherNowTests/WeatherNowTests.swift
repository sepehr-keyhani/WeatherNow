//
//  WeatherNowTests.swift
//  WeatherNowTests
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import XCTest
@testable import WeatherNow

@MainActor
final class WeatherNowTests: XCTestCase {

    private final class MockService: WeatherServicing {
        var weatherForCity: Weather?
        var weatherForCoords: Weather?
        var places: [Place] = []

        func fetchWeather(for city: String) async throws -> Weather { weatherForCity! }
        func fetchWeather(lat: Double, lon: Double) async throws -> Weather { weatherForCoords! }
        func searchPlaces(query: String) async throws -> [Place] { places }
    }

    func testSymbolMappingDayNight() {
        let day = Weather(city: "X", temperatureCelsius: 20, conditionDescription: "Clear", weatherCode: 0, isDay: true, latitude: nil, longitude: nil)
        let night = Weather(city: "X", temperatureCelsius: 20, conditionDescription: "Clear", weatherCode: 0, isDay: false, latitude: nil, longitude: nil)
        XCTAssertEqual(day.symbolName, "sun.max.fill")
        XCTAssertEqual(night.symbolName, "moon.stars.fill")
    }

    func testLoadByCoordinatesSetsHeaderAndWeather() async {
        let mock = MockService()
        mock.weatherForCoords = Weather(city: "Ottawa, Canada", temperatureCelsius: 12, conditionDescription: "Clear", weatherCode: 0, isDay: true, latitude: 0, longitude: 0)
        let vm = WeatherViewModel(service: mock, cache: WeatherCache())

        await vm.loadByCoordinates(lat: 0, lon: 0)

        XCTAssertEqual(vm.state.weather?.city, "Ottawa, Canada")
        XCTAssertEqual(vm.state.headerTitle, "Ottawa, Canada")
        XCTAssertFalse(vm.state.showingFavorites)
    }

    func testLiveSearchFiltersByWords() async {
        let mock = MockService()
        mock.places = [
            Place(name: "Tehran", country: "Iran", latitude: 0, longitude: 0),
            Place(name: "Tehran Province", country: "Iran", latitude: 0, longitude: 0),
            Place(name: "Toronto", country: "Canada", latitude: 0, longitude: 0),
        ]
        let vm = WeatherViewModel(service: mock, cache: WeatherCache())
        await vm.liveSearchPlaces(query: "Tehran Ir")
        XCTAssertEqual(vm.state.places.first?.name, "Tehran")
        XCTAssertTrue(vm.state.places.allSatisfy { $0.displayName.lowercased().contains("tehran") && $0.displayName.lowercased().contains("ir") })
    }

    func testToggleFavorite() {
        let vm = WeatherViewModel(service: MockService(), cache: WeatherCache())
        let p = Place(name: "Ottawa", country: "Canada", latitude: 0, longitude: 0)
        vm.toggleFavorite(p)
        XCTAssertTrue(vm.state.favorites.contains(p))
        vm.toggleFavorite(p)
        XCTAssertFalse(vm.state.favorites.contains(p))
    }
}
