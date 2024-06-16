//
//  MapViewModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation
import SwiftUI
import MapKit
import SwiftSoup



@objc(Dispensary)
class Dispensary: NSObject {
    var name: String
    var address: String
    var city: String
    var zipCode: String
    var website: String
    var fullAddress: String
    var idx: String?
    var coordinate: CLLocationCoordinate2D?
    
    init(name: String, address: String, city: String, zipCode: String, website: String, idx: String?, coordinate: CLLocationCoordinate2D?) {
        self.name = name
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.website = website
        self.coordinate = coordinate
        self.fullAddress = "\(address), \(city), \(zipCode)"

        self.idx = idx
    }
    
    func populateCoordinate() async {
        if self.coordinate != nil {
            return;
        }
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.geocodeAddressString(self.fullAddress)
            if let coordinate = placemarks.first?.location?.coordinate {
                self.coordinate = coordinate;
            }
        } catch {
            print("Geocoding failed with error: \(error.localizedDescription)")
        }
    }
    func getAnnotation() -> DispensaryAnnotation? {
        guard let coordinate = self.coordinate else {
            print("Can't get annotation, coordinate is nil")
            return nil
        }

        return DispensaryAnnotation(dispensary: self, name: self.name, address: self.fullAddress, coordinate: coordinate, idx: self.idx)
    }
}



class DispensaryAnnotation: NSObject, MKAnnotation {
    var dispensary: Dispensary
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var idx: String?
    
    init(dispensary: Dispensary, name: String, address: String, coordinate: CLLocationCoordinate2D, idx: String?) {
        self.dispensary = dispensary
        self.title = name
        self.subtitle = address
        self.coordinate = coordinate
        self.idx = idx
    }
}

class DispensaryManager {
    var geocoder = CLGeocoder()
    
    func fetchAndPrepareDispensaryData() async throws -> [Dispensary] {
        let urlString = "https://cannabis.ny.gov/dispensary-location-verification"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataDecodingError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to decode data into string"])
        }
        let dispensaries = parseHTMLContent(htmlString)
        return dispensaries
    }
    
    func fetchAnnotations(dispensaries: [Dispensary]) async throws -> [DispensaryAnnotation] {
        let annotations = await geocodeDispensaries(dispensaries: dispensaries)
        return annotations
    }
    
    
    private func parseHTMLContent(_ html: String) -> [Dispensary] {
        do {
            var dispensaries: [Dispensary] = []
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table tbody tr")
            
            for row in rows {
                let columns = try row.select("td")
                if columns.size() >= 5 {
                    let name = try columns.get(0).text()
                    let address = try columns.get(1).text()
                    let city = try columns.get(2).text()
                    let zipCode = try columns.get(3).text()
                    let website = try columns.get(4).text()
                    let numberPrefix = name.split(separator: ".").first?.trimmingCharacters(in: .whitespaces)
                    
                    let dispensary = Dispensary(
                        name: name,
                        address: address,
                        city: city,
                        zipCode: zipCode,
                        website: website,
                        idx: numberPrefix,
                        coordinate: nil
                    )
                    dispensaries.append(dispensary)
                }
            }
            return dispensaries
        } catch {
            print("Error parsing HTML: \(error)")
            return []
        }
    }
    
    private func geocodeDispensaries(dispensaries: [Dispensary]) async -> [DispensaryAnnotation] {
        var annotations: [DispensaryAnnotation] = []
        
        for dispensary in dispensaries {
            let fullAddress = "\(dispensary.address), \(dispensary.city), \(dispensary.zipCode)"
            if let numberPrefix = dispensary.name.split(separator: ".").first?.trimmingCharacters(in: .whitespaces) {
                if let annotation = await self.geocodeAddress(dispensary: dispensary, fullAddress: fullAddress, idx: numberPrefix) {
                    annotations.append(annotation)
                }
            }
        }
        
        return annotations
    }
    
    private func geocodeAddress(dispensary: Dispensary, fullAddress: String, idx: String) async -> DispensaryAnnotation? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            if let coordinate = placemarks.first?.location?.coordinate {
                return DispensaryAnnotation(dispensary: dispensary, name: dispensary.name, address: fullAddress, coordinate: coordinate, idx: idx)
            }
            return nil
        } catch {
            print("Geocoding failed with error: \(error.localizedDescription)")
            return nil
        }
    }
    
}


@MainActor
class MapViewModel: ObservableObject {
    @Published var allDispensaries: [Dispensary] = []
    @Published var dispensaryAnnotations: [DispensaryAnnotation] = []
    
    private var dispensaryManager = DispensaryManager()
    
    func loadData() async {
        do {
            allDispensaries = try await dispensaryManager.fetchAndPrepareDispensaryData()
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    func loadCoordinates(dispensary: Dispensary) async {
        if dispensary.coordinate != nil {
            return
        }
        await dispensary.populateCoordinate()

        if let annotation = dispensary.getAnnotation() {
            dispensaryAnnotations.append(annotation)
        } else {
            print("Was asked to load the annotation for dispensary \(dispensary.name) but couldn't do it")
        }
    }
    
    func loadAnnotations() async {
        do {
            dispensaryAnnotations = try await dispensaryManager.fetchAnnotations(dispensaries: allDispensaries)
        } catch {
            print("Failed to load data: \(error)")
        
        }
    }
}
