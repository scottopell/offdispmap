//
//  LocationManager.swift
//  offdispmap
//
//  Created by Scott Opell on 7/5/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // Handle denied or restricted status
            break
        default:
            break
        }
    }
    
    func getCoordinate(for fullAddress: String) -> CLLocationCoordinate2D? {
        // This method should return a cached coordinate if available
        // For this example, we'll just return nil
        return nil
    }
    
    func geocodeFullAddress(_ fullAddress: String) async throws -> CLLocationCoordinate2D? {
        do {
            Logger.info("Executing geocode for \"\(fullAddress)\"")
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            
            if let coordinate = placemarks.first?.location?.coordinate {
                Logger.info("Placemark found: \(placemarks.first!)")
                return coordinate
            }
        } catch let error as CLError {
            if error.code == .network {
                throw GeocodeError.network(error)
            } else {
                throw GeocodeError.other(error)
            }
        } catch {
            throw GeocodeError.other(error)
        }
        return nil
    }
}

enum GeocodeError: Error {
    case network(Error)
    case other(Error)
}
