//
//  LocationService.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private var authContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        if #available(iOS 14.0, *) {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
            manager.pausesLocationUpdatesAutomatically = false
        }
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.authContinuation = continuation
                self.manager.requestWhenInUseAuthorization()
            }
        } else if status == .denied || status == .restricted {
            return nil
        }

        manager.requestLocation()
        return await withCheckedContinuation { (continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>) in
            self.locationContinuation = continuation
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else {
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
            return
        }
        locationContinuation?.resume(returning: coord)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways || status == .denied || status == .restricted {
            authContinuation?.resume(returning: ())
            authContinuation = nil
        }
    }
}


