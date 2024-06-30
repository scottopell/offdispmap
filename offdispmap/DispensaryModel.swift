//
//  DispensaryModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/30/24.
//

import Foundation
import CoreLocation
import MapKit

@objc(Dispensary)
class Dispensary: NSObject {
    var name: String
    var address: String?
    var city: String?
    var zipCode: String?
    var website: String
    var url: URL?
    var fullAddress: String?
    var coordinate: CLLocationCoordinate2D?
    var isTemporaryDeliveryOnly: Bool
    var isNYC: Bool

    
    init(name: String, address: String, city: String, zipCode: String, website: String, coordinate: CLLocationCoordinate2D?) {
        var isTemporaryDeliveryOnly = false
        var name = name
        if name.hasSuffix("***") {
            name = name.replacingOccurrences(of: "***", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            isTemporaryDeliveryOnly = true
        }
        let url = normalizeURL(from: website)

        self.name = name
        self.address = address == "-" ? nil : address
        self.city = city == "-" ? nil : city
        self.zipCode = zipCode == "-" ? nil : zipCode
        self.website = website
        self.url = url
        self.isTemporaryDeliveryOnly = isTemporaryDeliveryOnly
        self.coordinate = coordinate
        self.fullAddress = "\(address), \(city), \(zipCode)"
        self.isNYC = false
    }
    // Implementation of CustomStringConvertible
    override var description: String {
        return """
        Dispensary(
            name: "\(name)",
            address: "\(address != nil ? "\(address!)" : "nil")",
            city: "\(city != nil ? "\(city!)" : "nil" )",
            zipCode: "\(zipCode != nil ? "\(zipCode!)" : "nil")",
            website: "\(website)",
            url: "\(url != nil ? "\(url!)" : "nil")",
            fullAddress: "\(fullAddress != nil ? "\(fullAddress!)" : "nil")",
            isTemporaryDeliveryOnly: \(isTemporaryDeliveryOnly),
            coordinate: \(coordinate.map { "(\($0.latitude), \($0.longitude))" } ?? "nil"),
            isNYC: \(isNYC)
        )
        """
    }
    
    func populateCoordinate() async {
        guard self.coordinate == nil && self.isTemporaryDeliveryOnly == false && self.fullAddress != nil else {
            return;
        }
        guard let fullAddress = self.fullAddress else {
            return;
        }
        do {
            let geocoder = CLGeocoder()
            Logger.info("Executing geocode for \(self.name) \"\(fullAddress)\"")
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            if let coordinate = placemarks.first?.location?.coordinate {
                Logger.info("All placemarks found: \(placemarks)")
                self.coordinate = coordinate
            }
        } catch {
            print("Geocoding failed with error: \(error.localizedDescription)")
        }
    }
    
    func getAnnotation() -> DispensaryAnnotation? {
        guard let coordinate = self.coordinate, let fullAddress = self.fullAddress else {
            print("Can't get annotation, coordinate is nil")
            return nil
        }

        return DispensaryAnnotation(dispensary: self, name: self.name, address: fullAddress, coordinate: coordinate)
    }
}

class DispensaryAnnotation: NSObject, MKAnnotation {
    var dispensary: Dispensary
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(dispensary: Dispensary, name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.dispensary = dispensary
        self.title = name
        self.subtitle = address
        self.coordinate = coordinate
    }
}
