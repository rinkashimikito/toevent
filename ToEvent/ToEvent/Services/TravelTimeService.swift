import Foundation
import MapKit
import CoreLocation

enum TravelTimeError: Error {
    case locationNotAvailable
    case directionsNotAvailable
    case noRoute
}

final class TravelTimeService {
    static let shared = TravelTimeService()

    private let geocoder = CLGeocoder()
    private var cache: [String: TimeInterval] = [:]

    private init() {}

    /// Calculate travel time from current location to destination address
    /// Returns travel time in seconds, or nil if calculation fails
    func calculateTravelTime(to address: String) async -> TimeInterval? {
        // Check cache first
        if let cached = cache[address] {
            return cached
        }

        // Geocode the address
        guard let destination = await geocodeAddress(address) else {
            return nil
        }

        // Calculate ETA
        do {
            let travelTime = try await calculateETA(to: destination)
            cache[address] = travelTime
            return travelTime
        } catch {
            return nil
        }
    }

    private func geocodeAddress(_ address: String) async -> CLLocation? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location
        } catch {
            return nil
        }
    }

    private func calculateETA(to destination: CLLocation) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: destination.coordinate)
        )
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculateETA()
        return response.expectedTravelTime
    }

    /// Calculate leave time for an event
    /// Returns the time user should leave to arrive on time
    func calculateLeaveTime(for event: Event) async -> Date? {
        guard let location = event.location, !location.isEmpty else {
            return nil
        }

        guard let travelTime = await calculateTravelTime(to: location) else {
            return nil
        }

        // Add 5 minute buffer
        let buffer: TimeInterval = 5 * 60
        return event.startDate.addingTimeInterval(-(travelTime + buffer))
    }

    /// Format travel time for display (e.g., "25 min" or "1h 15min")
    func formatTravelTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)min"
            }
        }
    }

    /// Clear the cache (useful when location changes significantly)
    func clearCache() {
        cache.removeAll()
    }
}
