//
//  DispensaryModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/30/24.
//

import Foundation
import CoreLocation
import MapKit

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
