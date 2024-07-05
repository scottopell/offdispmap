//
//  Dispensary+CoreDataProperties.swift
//  offdispmap
//
//  Created by Scott Opell on 7/5/24.
//

import Foundation
import CoreData
import CoreLocation

extension Dispensary {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dispensary> {
        return NSFetchRequest<Dispensary>(entityName: "Dispensary")
    }

    @NSManaged public var name: String
    @NSManaged public var address: String?
    @NSManaged public var city: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var website: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var isTemporaryDeliveryOnly: Bool
    @NSManaged public var isNYC: Bool

    public var coordinate: CLLocationCoordinate2D? {
        get {
            guard latitude != 0 && longitude != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.latitude ?? 0
            longitude = newValue?.longitude ?? 0
        }
    }

    public var url: URL? {
        get {
            return normalizeURL(from: website)
        }
        set {
            website = newValue?.absoluteString ?? ""
        }
    }
    
    public var fullAddress: String? {
        get {
            guard let address = address, let city = city, let zipCode = zipCode else {
                return nil
            }
            return "\(address), \(city), \(zipCode)"
        }
        set {
            // no-op
        }
    }
}

