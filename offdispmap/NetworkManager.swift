//
//  NetworkManager.swift
//  offdispmap
//
//  Created by Scott Opell on 6/30/24.
//

import Foundation

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

enum FetchError: Error {
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case unexpectedStatus(String)
}


struct ZipCode: Codable {
    let zip5: String
    let recordType: String?
}


struct USPSResponse: Codable {
    let resultStatus: String
    let city: String
    let state: String
    let zipList: [ZipCode]
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func fetchDispensaryData() async throws -> String {
        let urlString = "https://cannabis.ny.gov/dispensary-location-verification"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataDecodingError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to decode data into string"])
        }
        return htmlString
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
            return try DataParser.parseUSPSResponse(data).zipList
        } catch let error as DecodingError {
            throw FetchError.decodingError(error)
        } catch let error as FetchError {
            throw error
        } catch {
            throw FetchError.networkError(error)
        }    }

    // Add other networking methods as needed
}
