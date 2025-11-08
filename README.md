WeatherNow (UIKit • MVVM)

A small portfolio/sample app: current-location weather, live city search, and favorites — with a compact UIKit UI and MVVM. No API key required (Open‑Meteo).

Features

- Current location weather (fallback if denied)
- Live search (debounced), word-by-word matching
- Favorites: add/remove from card or list, persisted
- While searching: Favorites first, then results
- Day/night SF Symbols, small in‑memory cache

Tech

- Language/SDK: Swift 5+, iOS 26+ 
- Architecture: MVVM, protocol‑oriented seam (`WeatherServicing`), `@MainActor` ViewModel
- Concurrency: async/await, `Task`, `withCheckedContinuation` (for CoreLocation/authorization + CLGeocoder)
- Networking: Alamofire 5 (validate + Data serializer) calling Open‑Meteo Forecast & Geocoding APIs
- JSON: `JSONDecoder`
- UI: UIKit, Auto Layout via SnapKit, two‑section `UITableView`, `UIButton`/`UILabel`, `UIActivityIndicatorView`, `CAGradientLayer`, SF Symbols
- Location: CoreLocation (one‑shot best accuracy), CLGeocoder (Apple) with Open‑Meteo reverse geocode fallback
- Storage/Cache: `UserDefaults` (favorites), in‑memory TTL cache for recent weather
- Dependency Manager: CocoaPods
- Tests: XCTest (unit tests for ViewModel and symbol mapping; mocks via `WeatherServicing`)

Quick Start

1. Clone
   git clone https://github.com/sepehr-keyhani/WeatherNow.git
   cd WeatherNow
2. Install pods
   pod install
3. Open workspace
   open WeatherNow.xcworkspace
4. Run
   - Select a simulator/device
   - Product > Run (⌘R)
   - Allow Location (When In Use)

Tests

- Product > Test (⌘U)
- Tests in `WeatherNowTests/WeatherNowTests.swift`

Notes

License
Portfolio sample. Use freely; attribution appreciated.
