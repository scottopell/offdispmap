//
//  MapViewModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation
import CoreLocation
import CoreData

@MainActor
class MapViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var nycZipCodes: Set<String> = []
    @Published var errorMessage: String? = nil
    
    private let fetchedResultsController: NSFetchedResultsController<Dispensary>
        
    override init() {
        let fetchRequest: NSFetchRequest<Dispensary> = Dispensary.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.shared.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch dispensaries: \(error)")
        }
    }
    
    var allDispensaries: [Dispensary] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    var dispensaryAnnotations: [DispensaryAnnotation] {
        return allDispensaries.compactMap { dispensary in
            guard let coordinate = dispensary.coordinate else { return nil }
            return DispensaryAnnotation(dispensary: dispensary, name: dispensary.name, address: dispensary.fullAddress ?? "", coordinate: coordinate)
        }
    }
        
    
    func loadData() async {
        // Fetch new data in the background
        Task {
            await self.fetchAndUpdateData()
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
}
