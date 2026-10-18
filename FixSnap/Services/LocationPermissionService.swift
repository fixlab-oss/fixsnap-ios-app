import CoreLocation
import Foundation

@MainActor
final class LocationPermissionService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let lookupService = LocationLookupService()
    private var continuation: CheckedContinuation<LocationContext, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocationContext() async -> LocationContext {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            return .unavailable
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resume(with: .unavailable)
        case .notDetermined:
            break
        @unknown default:
            resume(with: .unavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            resume(with: .unavailable)
            return
        }

        Task {
            do {
                let context = try await lookupService.reverseGeocode(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                await MainActor.run {
                    resume(with: context)
                }
            } catch {
                await MainActor.run {
                    resume(with: LocationContext(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        countryCode: nil,
                        countryName: nil,
                        city: nil,
                        address: nil,
                        authorizationDenied: false
                    ))
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: .unavailable)
    }

    private func resume(with context: LocationContext) {
        continuation?.resume(returning: context)
        continuation = nil
    }
}
