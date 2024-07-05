//
//  MapView.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation

import SwiftUI
import MapKit

// referenced https://developer.apple.com/documentation/mapkit/mapkit_for_appkit_and_uikit/mapkit_annotations/annotating_a_map_with_custom_data
// while building this

struct MapView: UIViewRepresentable {
    var annotations: [DispensaryAnnotation]
    var selectedAnnotation: DispensaryAnnotation?
    var annotationFilter: ((DispensaryAnnotation) -> Bool)
    var onAnnotationSelect: ((DispensaryAnnotation) -> Void)?

    let nyc = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Default to NYC
        latitudinalMeters: 10000,
        longitudinalMeters: 10000
    )
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(DispensaryAnnotation.self))
        
        // Normally the "adjust region to fit annotations" logic handles the region of the map
        // This is just here in case something goes wrong
        mapView.setRegion(nyc, animated: false)
        
        // Add user tracking button
        let userTrackingButton = MKUserTrackingButton(mapView: mapView)
        userTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(userTrackingButton)
        
        NSLayoutConstraint.activate([
            userTrackingButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -10),
            userTrackingButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -10)
        ])
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove all existing annotations to prevent duplicates
        uiView.removeAnnotations(uiView.annotations)

        let displayAnnotations = annotations.filter(annotationFilter)
        
        // Add new annotations from the annotations binding
        uiView.addAnnotations(displayAnnotations)
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
            
            annotationView.canShowCallout = true
            annotationView.markerTintColor = .red
            annotationView.glyphText = annotation.title
            annotationView.clusteringIdentifier = "dispensary"
            
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? DispensaryAnnotation {
                parent.selectedAnnotation = annotation
                parent.onAnnotationSelect?(annotation)
            }
        }
    }
}
