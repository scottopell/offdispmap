//
//  MapView.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation

import SwiftUI
import MapKit
import SwiftSoup


struct Dispensary {
    var name: String
    var address: String
    var city: String
    var zipCode: String
    var website: String
}

class DispensaryAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var idx: String?
    
    init(name: String, address: String, coordinate: CLLocationCoordinate2D, idx: String?) {
        self.title = name
        self.subtitle = address
        self.coordinate = coordinate
        self.idx = idx  // Initialize the index
    }
}

class DispensaryManager {
    var geocoder = CLGeocoder()
    
    func fetchAndPrepareData() async throws -> ([Dispensary], [DispensaryAnnotation]) {
        let urlString = "https://cannabis.ny.gov/dispensary-location-verification"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        print("got url")
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataDecodingError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to decode data into string"])
        }
        print("fetched response")
        var dispensaries = parseHTMLContent(htmlString)
        dispensaries = Array(dispensaries.prefix(10))
        print("parsed html")
        let annotations = await geocodeDispensaries(dispensaries: dispensaries)
        print("got annotations \(annotations)")
        return (dispensaries, annotations)
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
                    
                    let dispensary = Dispensary(
                        name: name,
                        address: address,
                        city: city,
                        zipCode: zipCode,
                        website: website
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
            print("Starting geocoding for: \(fullAddress)")
            if let numberPrefix = dispensary.name.split(separator: ".").first?.trimmingCharacters(in: .whitespaces) {
                if let annotation = await self.geocodeAddress(dispensary: dispensary, fullAddress: fullAddress, idx: numberPrefix) {
                    annotations.append(annotation)
                    print("Geocoding completed for: \(fullAddress) with result: \(annotation)")
                }
            }
        }
        
        return annotations
    }
    
    private func geocodeAddress(dispensary: Dispensary, fullAddress: String, idx: String) async -> DispensaryAnnotation? {
        do {
            print("Attempting to geocode \(fullAddress)")
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            print("Got placemarks for address \(placemarks)")
            if let coordinate = placemarks.first?.location?.coordinate {
                return DispensaryAnnotation(name: dispensary.name, address: fullAddress, coordinate: coordinate, idx: idx)
            }
            return nil
        } catch {
            print("Geocoding failed with error: \(error.localizedDescription)")
            return nil
        }
    }
    
}

struct MapView: UIViewRepresentable {
    @Binding var annotations: [DispensaryAnnotation]
    @Binding var selectedAnnotation: DispensaryAnnotation?
    
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(DispensaryAnnotation.self))
        
        let nyc = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Default to NYC
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        mapView.setRegion(nyc, animated: true)
        
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove all existing annotations to prevent duplicates
        uiView.removeAnnotations(uiView.annotations)
        
        // Add new annotations from the annotations binding
        uiView.addAnnotations(annotations)
        
        if let selectedAnnotation = selectedAnnotation {
            let region = MKCoordinateRegion(center: selectedAnnotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            uiView.setRegion(region, animated: true)
        } else {
            updateMapRegionToFitAnnotations(uiView)
            
        }
    }
    
    private func updateMapRegionToFitAnnotations(_ mapView: MKMapView) {
        guard !mapView.annotations.isEmpty else { return }
        
        // Create a region that encompasses all annotations
        let annotations = mapView.annotations
        let mapRects = annotations.map { MKMapRect(origin: MKMapPoint($0.coordinate), size: MKMapSize(width: 0, height: 0)) }
        let fittingRect = mapRects.reduce(MKMapRect.null) { $0.union($1) }
        
        // Update the map view to show this region with some additional padding
        mapView.setVisibleMapRect(fittingRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            guard !annotation.isKind(of: MKUserLocation.self) else {
                // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
                return nil
            }
            
            var annotationView: MKAnnotationView?
            
            if let annotation = annotation as? DispensaryAnnotation {
                annotationView = setupDispensaryAnnotationView(for: annotation, on: mapView)
            }
            
            return annotationView
        }
        
        private func setupDispensaryAnnotationView(for annotation: DispensaryAnnotation, on mapView: MKMapView) -> MKAnnotationView {
            let reuseIdentifier = NSStringFromClass(DispensaryAnnotation.self)
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            annotationView.canShowCallout = true  // Enables the popup with title and subtitle on tap
            
            // Optionally, set a simple glyph (text) or color if needed
            annotationView.markerTintColor = .blue  // Set the marker tint color to blue
            
            if let idx = annotation.idx {
                annotationView.glyphText = String(idx)  // Ensuring it's treated as a String
            } else {
                annotationView.glyphText = "?"  // Default value if index isn't set
            }
            
            
            return annotationView
        }
        
        
    }
}
