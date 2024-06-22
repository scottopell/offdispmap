//
//  DispensaryData.swift
//  offdispmap
//
//  Created by Scott Opell on 6/22/24.
//

import Foundation
import CoreLocation

struct DispensaryData {
    static let shared = DispensaryData()
    
    private init() {}
    
    // Lookup table for dispensary coordinates
    let dispensaryCoordinates: [String: CLLocationCoordinate2D] = [
        // Example data, you'll replace this with actual data
        "Dispensary1": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        "Dispensary2": CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
        // Add more dispensaries here
    ]
    
    // Function to get coordinate for a dispensary
    func getCoordinate(for dispensaryName: String) -> CLLocationCoordinate2D? {
        return dispensaryCoordinates[dispensaryName]
    }
    
    // List of NYC zip codes
    let nycZipCodes: Set<String> = [
        "10001", "10002", "10003", "10004", "10005", "10006", "10007", "10009",
        "10010", "10011", "10012", "10013", "10014", "10016", "10017", "10018",
        "10019", "10020", "10021", "10022", "10023", "10024", "10025", "10026",
        "10027", "10028", "10029", "10030", "10031", "10032", "10033", "10034",
        "10035", "10036", "10037", "10038", "10039", "10040", "10044", "10065",
        "10075", "10128", "10280", "10282", "11101", "11201", "11205", "11211",
        "11215", "11217", "11231"
    ]
}
