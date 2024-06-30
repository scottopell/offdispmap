//
//  DataParser.swift
//  offdispmap
//
//  Created by Scott Opell on 6/30/24.
//

import Foundation
import SwiftSoup

class DataParser {
    static func parseDispensaryHTML(_ html: String) -> [Dispensary] {
        do {
            var dispensaries: [Dispensary] = []
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table tbody tr")
            
            for row in rows {
                let columns = try row.select("td")
                if columns.size() >= 5 {
                    let name = try columns.get(0).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let address = try columns.get(1).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let city = try columns.get(2).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let zipCode = try columns.get(3).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    let website = try columns.get(4).text().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let dispensary = Dispensary(
                        name: name,
                        address: address,
                        city: city,
                        zipCode: zipCode,
                        website: website,
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

    static func parseUSPSResponse(_ data: Data) throws -> USPSResponse {
            let decoder = JSONDecoder()
            
            do {
                let response = try decoder.decode(USPSResponse.self, from: data)
                
                // Validate the response status
                guard response.resultStatus == "SUCCESS" else {
                    throw FetchError.unexpectedStatus(response.resultStatus)
                }
                
                return response
            } catch let decodingError as DecodingError {
                // Handle specific decoding errors
                switch decodingError {
                case .keyNotFound(let key, _):
                    throw FetchError.decodingError(NSError(domain: "USPSParsingError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Missing key in USPS response: \(key.stringValue)"]))
                case .valueNotFound(_, let context):
                    throw FetchError.decodingError(NSError(domain: "USPSParsingError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Missing value in USPS response: \(context.debugDescription)"]))
                case .typeMismatch(_, let context):
                    throw FetchError.decodingError(NSError(domain: "USPSParsingError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Type mismatch in USPS response: \(context.debugDescription)"]))
                case .dataCorrupted(let context):
                    throw FetchError.decodingError(NSError(domain: "USPSParsingError", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Data corrupted in USPS response: \(context.debugDescription)"]))
                @unknown default:
                    throw FetchError.decodingError(decodingError)
                }
            } catch {
                // Handle any other errors
                throw FetchError.decodingError(error)
            }
        }
}
