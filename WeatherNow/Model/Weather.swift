//
//  Weather.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import Foundation

struct Weather: Equatable {
    let city: String
    let temperatureCelsius: Double
    let conditionDescription: String
    let weatherCode: Int
    let isDay: Bool
    let latitude: Double?
    let longitude: Double?

    var formattedTemperature: String {
        String(format: "%.0f℃", temperatureCelsius)
    }

    // SF Symbol based on weather code and day/night
    var symbolName: String {
        switch weatherCode {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1: return isDay ? "sun.min.fill" : "moon.fill"
        case 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return isDay ? "cloud.drizzle.fill" : "cloud.drizzle"
        case 61, 63, 65, 80, 81, 82: return isDay ? "cloud.rain.fill" : "cloud.heavyrain.fill"
        case 66, 67: return "cloud.hail.fill"
        case 71, 73, 75, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud"
        }
    }
}


