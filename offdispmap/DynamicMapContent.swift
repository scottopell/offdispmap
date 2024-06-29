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
    var url: URL?
    var fullAddress: String
    var coordinate: CLLocationCoordinate2D?
    var isTemporaryDeliveryOnly: Bool

    
    init(name: String, address: String, city: String, zipCode: String, website: String, url: URL?, isTemporaryDeliveryOnly: Bool, coordinate: CLLocationCoordinate2D?) {
        self.name = name
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.website = website
        self.url = url
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
            url: "\(url != nil ? "\(url!)" : "nil")",
            fullAddress: "\(fullAddress)",
            isTemporaryDeliveryOnly: \(isTemporaryDeliveryOnly),
            coordinate: \(coordinate.map { "(\($0.latitude), \($0.longitude))" } ?? "nil")
        )
        """
    }
    
    func populateCoordinate() async {
        guard self.coordinate == nil && self.isTemporaryDeliveryOnly == false  else {
            return;
        }
        do {
            let geocoder = CLGeocoder()
            Logger.info("Executing geocode for \(self.name) \"\(self.fullAddress)\"")
            let placemarks = try await geocoder.geocodeAddressString(self.fullAddress)
            if let coordinate = placemarks.first?.location?.coordinate {
                Logger.info("All placemarks found: \(placemarks)")
                self.coordinate = coordinate
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

func normalizeURL(from input: String) -> URL? {
    var urlString = input.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check if the input already has a scheme
    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
        urlString = "https://\(urlString)"
    }
    
    // Attempt to create a URL, auto-encoding invalid characters if necessary
    if let url = URL(string: urlString) {
        return url
    } else {
        // Attempt to use URLComponents for further correction
        if var components = URLComponents(string: urlString) {
            if components.scheme == nil {
                components.scheme = "https"
            }
            return components.url
        }
    }
    
    return nil
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
        for dispensary in dispensaries {
            if dispensary.coordinate == nil {
                await dispensary.populateCoordinate()
            }
        }
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
                    
                    let url = normalizeURL(from: website)
                    
                    let dispensary = Dispensary(
                        name: name,
                        address: address,
                        city: city,
                        zipCode: zipCode,
                        website: website,
                        url: url,
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

struct USPSResponse: Codable {
    let resultStatus: String
    let city: String
    let state: String
    let zipList: [ZipCode]
}

struct ZipCode: Codable {
    let zip5: String
    let recordType: String?
}

enum FetchError: Error {
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case unexpectedStatus(String)
}

func fetchZipCodes(for city: String, state: String) async throws -> [ZipCode] {
    let url = URL(string: "https://tools.usps.com/tools/app/ziplookup/zipByCityState")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = "city=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)&state=\(state)".data(using: .utf8)

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FetchError.invalidResponse
        }

        let decoder = JSONDecoder()
        let uspsResponse = try decoder.decode(USPSResponse.self, from: data)
        
        guard uspsResponse.resultStatus == "SUCCESS" else {
            throw FetchError.unexpectedStatus(uspsResponse.resultStatus)
        }
        
        return uspsResponse.zipList
    } catch let error as DecodingError {
        throw FetchError.decodingError(error)
    } catch let error as FetchError {
        throw error
    } catch {
        throw FetchError.networkError(error)
    }
}

func fetchAllNYCZipCodes() async throws -> [String] {
    let boroughs = [
        ("Manhattan", "NY"),
        ("Brooklyn", "NY"),
        ("Queens", "NY"),
        ("Bronx", "NY"),
        ("Staten Island", "NY")
    ]
    
    var allZipCodes: Set<String> = []
    
    for (borough, state) in boroughs {
        do {
            let zipCodes = try await fetchZipCodes(for: borough, state: state)
            allZipCodes.formUnion(zipCodes.map { $0.zip5 })
        } catch {
            print("Error fetching zip codes for \(borough): \(error)")
            // Continue with other boroughs even if one fails
        }
    }
    
    return Array(allZipCodes).sorted()
}


@MainActor
class MapViewModel: ObservableObject {
    @Published var allDispensaries: [Dispensary] = []
    @Published var dispensaryAnnotations: [DispensaryAnnotation] = []
    @Published var nycZipCodes: Set<String> = []
    @Published var errorMessage: String? = nil
    
    private var dispensaryManager = DispensaryManager()
    
    func loadData() async {
        do {
            async let dispensariesTask = dispensaryManager.fetchAndPrepareDispensaryData()
            async let zipCodesTask = fetchAllNYCZipCodes()
            
            let (fetchedDispensaries, fetchedZipCodes) = try await (dispensariesTask, zipCodesTask)
            
            allDispensaries = fetchedDispensaries
            nycZipCodes = Set(fetchedZipCodes)
            for dispensary in allDispensaries {
                if dispensary.coordinate != nil {
                    populateAnnotation(for: dispensary)
                }
            }
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let fetchError = error as? FetchError {
            switch fetchError {
            case .invalidResponse:
                errorMessage = "Invalid response from server"
            case .networkError(let underlyingError):
                errorMessage = "Network error: \(underlyingError.localizedDescription)"
            case .decodingError(let underlyingError):
                errorMessage = "Data decoding error: \(underlyingError.localizedDescription)"
            case .unexpectedStatus(let status):
                errorMessage = "Unexpected status: \(status)"
            }
        } else {
            errorMessage = "An unknown error occurred: \(error.localizedDescription)"
        }
        
        print("Failed to load data: \(errorMessage ?? "Unknown error")")
    }

    func logCoordinates(onlyNonCached: Bool) -> String {
        var log = "let dispensaryCoordinates: [String: CLLocationCoordinate2D] = [\""
        for dispensary in allDispensaries {
            if let coordinate = dispensary.coordinate {
                if !onlyNonCached || (onlyNonCached && DispensaryData.shared.getCoordinate(for: dispensary.fullAddress) == nil) {
                    log += "\"\(dispensary.fullAddress)\": CLLocationCoordinate2D(latitude: \(coordinate.latitude), longitude: \(coordinate.longitude)),\n"
                }
            }
        }
        log += "]"
        return log
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

        populateAnnotation(for: dispensary)
    }
}
