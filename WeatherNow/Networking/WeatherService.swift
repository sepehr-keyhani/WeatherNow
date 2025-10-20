//
//  WeatherService.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import Foundation
import Alamofire
import CoreLocation

enum WeatherAPIError: LocalizedError {
    case invalidURL
    case notFound
    case decodingFailed
    case network(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .notFound:
            return "Location not found."
        case .decodingFailed:
            return "Failed to decode weather data."
        case .network(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}

struct OpenMeteoGeoResponse: Decodable {
    struct Place: Decodable {
        let name: String
        let country: String?
        let latitude: Double
        let longitude: Double
    }
    let results: [Place]?
}

struct OpenMeteoForecastResponse: Decodable {
    struct CurrentWeather: Decodable { let temperature: Double; let weathercode: Int; let is_day: Int }
    let current_weather: CurrentWeather?
}

protocol WeatherServicing {
    func fetchWeather(for city: String) async throws -> Weather
    func fetchWeather(lat: Double, lon: Double) async throws -> Weather
    func searchPlaces(query: String) async throws -> [Place]
}

final class WeatherService: WeatherServicing {
    init() {}
    
    func fetchWeather(for city: String) async throws -> Weather {
        guard let q = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let geoURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(q)&count=10&language=en&format=json") else {
            throw WeatherAPIError.invalidURL
        }
        
        do {
            let geoData: Data = try await AF.request(geoURL)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            let geo = try JSONDecoder().decode(OpenMeteoGeoResponse.self, from: geoData)
            guard let places = geo.results, !places.isEmpty else { throw WeatherAPIError.notFound }
            let first = places[0]
            return try await fetchWeather(lat: first.latitude, lon: first.longitude, displayName: first.name, country: first.country)
        } catch let err as WeatherAPIError {
            throw err
        } catch let decoding as DecodingError {
            print("Decoding error: \(decoding)")
            throw WeatherAPIError.decodingFailed
        } catch {
            throw WeatherAPIError.network(underlying: error)
        }
    }

    
    func fetchWeather(lat: Double, lon: Double) async throws -> Weather {
        return try await fetchWeather(lat: lat, lon: lon, displayName: nil, country: nil)
    }
    
    private func fetchWeather(lat: Double, lon: Double, displayName: String?, country: String?) async throws -> Weather {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true") else {
            throw WeatherAPIError.invalidURL
        }
        do {
            let data: Data = try await AF.request(url)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
            guard let cw = decoded.current_weather else { throw WeatherAPIError.decodingFailed }
            
            var resolvedCity = displayName ?? ""
            var resolvedCountry = country
            if resolvedCity.isEmpty {
                // Prefer Apple's CLGeocoder (more precise locality) then fall back to Open-Meteo
                if let apple = try? await reverseGeocodeApple(lat: lat, lon: lon) {
                    resolvedCity = apple.name
                    resolvedCountry = apple.country
                } else if let rev = try? await reverseGeocode(lat: lat, lon: lon) {
                    resolvedCity = rev.name
                    resolvedCountry = rev.country
                }
            }
            
            let description = Self.description(for: cw.weathercode)
            return Weather(
                city: [resolvedCity, resolvedCountry].compactMap { $0 }.joined(separator: ", "),
                temperatureCelsius: cw.temperature,
                conditionDescription: description,
                weatherCode: cw.weathercode,
                isDay: cw.is_day == 1,
                latitude: lat,
                longitude: lon
            )
        } catch let err as WeatherAPIError {
            throw err
        } catch let decoding as DecodingError {
            print("Decoding error: \(decoding)")
            throw WeatherAPIError.decodingFailed
        } catch {
            throw WeatherAPIError.network(underlying: error)
        }
    }
    
    private func reverseGeocode(lat: Double, lon: Double) async throws -> (name: String, country: String?) {
        guard let url = URL(string: "https://geocoding-api.open-meteo.com/v1/reverse?latitude=\(lat)&longitude=\(lon)&count=1&language=en&format=json") else {
            throw WeatherAPIError.invalidURL
        }
        let data: Data = try await AF.request(url)
            .validate(statusCode: 200..<300)
            .serializingData()
            .value
        let geo = try JSONDecoder().decode(OpenMeteoGeoResponse.self, from: data)
        guard let place = geo.results?.first else { throw WeatherAPIError.notFound }
        return (place.name, place.country)
    }

    // Fallback using Apple's CLGeocoder to ensure we have a readable city string
    private func reverseGeocodeApple(lat: Double, lon: Double) async throws -> (name: String, country: String?) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let p = placemarks?.first else {
                    continuation.resume(throwing: WeatherAPIError.notFound)
                    return
                }
                let name = p.locality ?? p.name ?? p.administrativeArea ?? ""
                let country = p.country
                continuation.resume(returning: (name, country))
            }
        }
    }

    func searchPlaces(query: String) async throws -> [Place] {
        guard let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(q)&count=10&language=en&format=json") else {
            throw WeatherAPIError.invalidURL
        }
        let data: Data = try await AF.request(url)
            .validate(statusCode: 200..<300)
            .serializingData()
            .value
        let geo = try JSONDecoder().decode(OpenMeteoGeoResponse.self, from: data)
        return (geo.results ?? []).map { Place(name: $0.name, country: $0.country, latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    private static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }
}



