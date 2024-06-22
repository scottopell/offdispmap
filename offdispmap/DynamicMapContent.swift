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
    var coordinate: CLLocationCoordinate2D?
    var isTemporaryDeliveryOnly: Bool

    
    init(name: String, address: String, city: String, zipCode: String, website: String, isTemporaryDeliveryOnly: Bool, coordinate: CLLocationCoordinate2D?) {
        self.name = name
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.website = website
        self.isTemporaryDeliveryOnly = isTemporaryDeliveryOnly
        self.coordinate = coordinate
        self.fullAddress = "\(address), \(city), \(zipCode)"
    }
    // Implementation of CustomStringConvertible
    override var description: String {
        return """
        Dispensary(
            name: "\(name)",
            address: "\(address)",
            city: "\(city)",
            zipCode: "\(zipCode)",
            website: "\(website)",
            fullAddress: "\(fullAddress)",
            isTemporaryDeliveryOnly: \(isTemporaryDeliveryOnly),
            coordinate: \(coordinate.map { "(\($0.latitude), \($0.longitude))" } ?? "nil")
        )
        """
    }
    
    func populateCoordinate() async {
        if self.coordinate != nil {
            return;
        }
        if let coordinate = DispensaryData.shared.getCoordinate(for: self.fullAddress) {
            self.coordinate = coordinate
        } else {
            // Fallback to geocoding if not found in lookup table
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.geocodeAddressString(self.fullAddress)
                if let coordinate = placemarks.first?.location?.coordinate {
                    self.coordinate = coordinate
                }
            } catch {
                print("Geocoding failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    func getAnnotation() -> DispensaryAnnotation? {
        guard let coordinate = self.coordinate else {
            print("Can't get annotation, coordinate is nil")
            return nil
        }

        return DispensaryAnnotation(dispensary: self, name: self.name, address: self.fullAddress, coordinate: coordinate)
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
    
    // todo surface There are currently 134 adult-use cannabis dispensaries across
    private func parseHTMLContent(_ html: String) -> [Dispensary] {
        do {
            var dispensaries: [Dispensary] = []
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table tbody tr")
            
            for row in rows {
                let columns = try row.select("td")
                if columns.size() >= 5 {
                    var name = try columns.get(0).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let address = try columns.get(1).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let city = try columns.get(2).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let zipCode = try columns.get(3).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let website = try columns.get(4).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    var isTemporaryDeliveryOnly = false
                    if name.hasSuffix("***") {
                        name = name.replacingOccurrences(of: "***", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        isTemporaryDeliveryOnly = true
                    }
                    
                    let dispensary = Dispensary(
                        name: name,
                        address: address,
                        city: city,
                        zipCode: zipCode,
                        website: website,
                        isTemporaryDeliveryOnly: isTemporaryDeliveryOnly,
                        coordinate: nil
                    )
                    dispensary.coordinate = DispensaryData.shared.getCoordinate(for: dispensary.fullAddress)

                    Logger.info("Parsed dispensary and here it is \(dispensary)")
                    dispensaries.append(dispensary)
                }
            }
            return dispensaries
        } catch {
            print("Error parsing HTML: \(error)")
            return []
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
            for dispensary in allDispensaries {
                if dispensary.coordinate != nil {
                    Logger.info("Dispensary \(dispensary) has a coordinate, lets put an annotation for it")
                    populateAnnotation(for: dispensary)
                }
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    func logCoordinates() {
        print("let dispensaryCoordinates: [String: CLLocationCoordinate2D] = [")
        for dispensary in allDispensaries {
            if let coordinate = dispensary.coordinate {
                print("    \"\(dispensary.fullAddress)\": CLLocationCoordinate2D(latitude: \(coordinate.latitude), longitude: \(coordinate.longitude)),")
            }
        }
        print("]")
    }
    
    func populateAnnotation(for dispensary: Dispensary) {
         if let annotation = dispensary.getAnnotation() {
            dispensaryAnnotations.append(annotation)
        } else {
            print("Was asked to load the annotation for dispensary \(dispensary.name) but couldn't do it")
        }
    }
    
    func loadCoordinates(dispensary: Dispensary) async {
        if dispensary.isTemporaryDeliveryOnly || dispensary.coordinate != nil {
            return
        }
        await dispensary.populateCoordinate()
        logCoordinates()

        populateAnnotation(for: dispensary)
    }
}
