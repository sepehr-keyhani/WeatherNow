WeatherNow (UIKit • MVVM)

Overview
WeatherNow is a portfolio/sample iOS app that demonstrates a clean UIKit + MVVM implementation of a simple weather client with live city search, current-location weather, favorites, caching, and a modern, compact UI built with SnapKit. Networking uses Alamofire with Open‑Meteo (no API key required).

Key Features

- Current location weather with graceful fallback
- Live city search (word-by-word) with debounced queries
- Two-section list UX while searching: Favorites first, then results
- Favorites: add/remove from card or list (persisted with UserDefaults)
- Inline weather preview for favorite cities (loads asynchronously)
- Simple in‑memory cache (TTL) for recent queries
- Day/Night SF Symbol mapping based on weather code
- No API key required (Open‑Meteo + Open‑Meteo Geocoding)

Tech Stack

- UIKit, SnapKit (layout)
- MVVM with a small `WeatherServicing` protocol seam for testability
- Concurrency: async/await, `@MainActor` ViewModel
- Alamofire for networking (Data serializer + JSONDecoder)
- CoreLocation (one‑shot best accuracy), CLGeocoder fallback for city name
- Unit tests (XCTest) for ViewModel logic and symbol mapping

Project Structure (high level)

- WeatherNow/
  - Model/ — `Weather`, `Place`
  - Networking/ — `WeatherService` (conforms to `WeatherServicing`)
  - ViewModel/ — `WeatherViewModel` (@MainActor)
  - Cache/ — `WeatherCache`, `FavoritesStore`
  - Location/ — `LocationService`
  - ViewController.swift — UIKit screen, SnapKit layout, 2‑section table
  - Assets.xcassets/ — AppIcon & colors
  - Info.plist — contains location usage description key

Requirements

- macOS with Xcode 16 (iOS SDK 17/18 compatible)
- iOS Deployment Target: 16.0+
- CocoaPods installed (`sudo gem install cocoapods`)

Setup & Run

1. Clone the repo
   git clone https://github.com/your-name/WeatherNow.git
   cd WeatherNow

2. Install pods
   pod install

3. Open the workspace (not the .xcodeproj)
   open WeatherNow.xcworkspace

4. Build & Run
   - Select a simulator or a device
   - Product > Run (⌘R)
   - On first launch, allow Location access (When In Use)

Notes

- API keys: Not required (Open‑Meteo). If you see an old `OPENWEATHER_API_KEY` in Info.plist, it is unused.
- Location Name: The app prefers Apple CLGeocoder for accurate locality names, with Open‑Meteo reverse geocoding as fallback.
- App Icon: A single 1024×1024 PNG is referenced by the AppIcon set. If Xcode shows a warning, replace the image in `Assets.xcassets/AppIcon.appiconset/` with a real 1024×1024 PNG and clean build.

Testing

- Unit tests live in `WeatherNowTests/WeatherNowTests.swift`
- Run: Product > Test (⌘U)
- The Podfile configures test targets to inherit search paths; ensure you opened the `.xcworkspace`

Troubleshooting

- Pods not found / Build phases rsync errors
  - Run `pod install` again
  - Open `.xcworkspace`
  - Clean build folder (Shift+⌘K)
- Location shows wrong or empty city name
  - Ensure you allowed location When In Use
  - Simulator: set a custom GPX or a location from Features > Location
- App icon warning (red badge)
  - Replace the 1024×1024 PNG in AppIcon set, then clean build

Architecture Notes

- ViewModel is annotated with `@MainActor` so `state` mutations and UI notifications are serialized on the main actor. Network and decoding work off the main actor, then results are applied back on main.
- The networking layer exposes a protocol `WeatherServicing` to enable injecting mocks in unit tests.

Roadmap (nice‑to‑have)

- Offline persistence for last viewed city and favorite weathers
- Hourly/weekly forecast details
- Pull‑to‑refresh & background refresh
- Haptics & small animations on favorite toggles

License & Use
This project is provided as a learning/portfolio sample. Feel free to clone and experiment. Attribution appreciated.

Questions?
If anything is unclear or you’d like a short Loom/video walkthrough, open an issue or ping me, and I’ll add it.
