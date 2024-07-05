//
//  MapViewModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    @Published var dispensaryAnnotations: [DispensaryAnnotation] = []
    @Published var nycZipCodes: Set<String> = []
    @Published var errorMessage: String? = nil
    
    var allDispensaries: [Dispensary] {
        CoreDataManager.shared.fetchDispensaries()
    }
        
    
    func loadData() async {
        self.updateAnnotations()
        
        // Fetch new data in the background
        Task {
            await self.fetchAndUpdateData()
        }
    }
    
    private func updateAnnotations() {
        self.dispensaryAnnotations = self.allDispensaries.compactMap { dispensary in
            guard let coordinate = dispensary.coordinate else { return nil }
            return DispensaryAnnotation(dispensary: dispensary, name: dispensary.name, address: dispensary.fullAddress ?? "", coordinate: coordinate)
        }
    }

    func fetchAndUpdateData() async {
        do {
            async let dispensariesTask = NetworkManager.shared.fetchDispensaryData()
            async let zipCodesTask = NetworkManager.shared.fetchAllNYCZipCodes()
            
            let (dispensariesHTML, fetchedZipCodes) = try await (dispensariesTask, zipCodesTask)
            let parsedDispensaries = DataParser.parseDispensaryHTML(dispensariesHTML)
            nycZipCodes = Set(fetchedZipCodes)
            for parsedDispensary in parsedDispensaries {
                var isTemporaryDeliveryOnly = false
                var name = parsedDispensary.name
                if name.hasSuffix("***") {
                    name = name.replacingOccurrences(of: "***", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    isTemporaryDeliveryOnly = true
                }
                
                if let dispensary = CoreDataManager.shared.createOrUpdateDispensary(
                    name: name,
                    address: parsedDispensary.address,
                    city: parsedDispensary.city,
                    zipCode: parsedDispensary.zipCode,
                    website: parsedDispensary.website,
                    isTemporaryDeliveryOnly: isTemporaryDeliveryOnly,
                    isNYC: nycZipCodes.contains(where: {$0 == parsedDispensary.zipCode})
                ) {
                    if !isTemporaryDeliveryOnly {
                        try await loadAddressForDispensary(dispensary)
                    }
                }
            }
            CoreDataManager.shared.saveContext()
            self.updateAnnotations()
        } catch {
            handleError(error)
        }
    }
    
    private func loadAddressForDispensary(_ dispensary: Dispensary) async throws {
        if dispensary.coordinate != nil {
            return;
        }
        guard let fullAddress = dispensary.fullAddress else {
            return;
        }
        if let coordinate = DispensaryData.shared.getCoordinate(for: fullAddress) {
            dispensary.latitude = coordinate.latitude
            dispensary.longitude = coordinate.longitude
        } else {
            // If lookup fails, then this entry needs to be geocoded.
            // If the geocoding fails, this dispensary is skipped
            // This could result in incomplete listings,
            // so TODO background periodic refresh.
            if let coordinate = try await LocationManager.shared.geocodeFullAddress(fullAddress) {
                dispensary.latitude = coordinate.latitude
                dispensary.longitude = coordinate.longitude
            }
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
        } else if let geocodeError = error as? GeocodeError {
            switch geocodeError {
            case .network(let underlyingError):
                errorMessage = "Too many address lookups, data will slowly populate. Error: \(underlyingError.localizedDescription)"
            case .other(let underlyingError):
                errorMessage = "Geocoding error: \(underlyingError.localizedDescription)"
            }
        } else {
            errorMessage = "An unknown error occurred: \(error.localizedDescription)"
        }
        
        print("Failed to load data: \(errorMessage ?? "Unknown error")")
    }
    
    func populateAnnotation(for dispensary: Dispensary) {
        guard let coordinate = dispensary.coordinate, let fullAddress = dispensary.fullAddress else {
            print("Can't get annotation, coordinate is nil")
            return
        }

        let annotation = DispensaryAnnotation(dispensary: dispensary, name: dispensary.name, address: fullAddress, coordinate: coordinate)

        
        dispensaryAnnotations.append(annotation)
    }
}
