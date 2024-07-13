//
//  Dispensary+CoreDataProperties.swift
//  offdispmap
//
//  Created by Scott Opell on 7/5/24.
//

import Foundation
import CoreData
import CoreLocation

struct Dispensary: Identifiable {
    
    let id = UUID()
    public var name: String
    public var address: String?
    public var city: String?
    public var zipCode: String?
    public var website: String
    public var latitude: Double
    public var longitude: Double
    public var isTemporaryDeliveryOnly: Bool
    public var isNYC: Bool
    public var coordinate: CLLocationCoordinate2D?
    public let url: URL?
    public let fullAddress: String?
    
    init(name: String, address: String? = nil, city: String? = nil, zipCode: String? = nil, website: String, latitude: Double, longitude: Double, isTemporaryDeliveryOnly: Bool, isNYC: Bool, coordinate: CLLocationCoordinate2D? = nil, url: URL?, fullAddress: String?) {
        self.name = name
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.website = website
        self.latitude = latitude
        self.longitude = longitude
        self.isTemporaryDeliveryOnly = isTemporaryDeliveryOnly
        self.isNYC = isNYC
        self.coordinate = coordinate
        self.url = url
        self.fullAddress = fullAddress
    }
}

extension DispensaryCoreData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DispensaryCoreData> {
        return NSFetchRequest<DispensaryCoreData>(entityName: "Dispensary")
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
    
    var toStruct: Dispensary {
        Dispensary(name: name, website: website, latitude: latitude, longitude: longitude, isTemporaryDeliveryOnly: isTemporaryDeliveryOnly, isNYC: isNYC, url: url, fullAddress: fullAddress)
    }
}

