//
//  MainViewModel.swift
//  offdispmap
//
//  Created by Brian Floersch on 7/14/24.
//

import Foundation
import CoreData
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var selectedDispensary: Dispensary?
    @Published var selectedAnnotation: DispensaryAnnotation?
    @Published var displayDispensaries: [Dispensary] = []
    @Published var hasFetched = false
    @Published var isLoading = false
    @Published var nycOnlyMode = true
    @Published var deliveryOnlyMode = false
    @Published var selectedTab = "map"
    @Published var errorMessage: String?
    
    func fetchDispensaries() {
        dispensaries = CoreDataManager.shared.fetchDispensaries()
    }
    
    var dispensaries: [DispensaryCoreData] = [] {
        didSet {
            displayDispensaries = dispensaries.filter { dispensary in
                if deliveryOnlyMode && dispensary.isTemporaryDeliveryOnly == false {
                    return false
                }
                if nycOnlyMode && dispensary.isNYC == false {
                    return false
                }
                return true
            }.map { $0.toStruct }
        }
    }
    
    
    var headerTitle: String {
        let place = nycOnlyMode ? "NYC" : "NY"
        return "\(place) Dispensaries"
    }
    
    var dispensaryAnnotations: [DispensaryAnnotation] {
        dispensaries.compactMap { dispensary in
            guard let coordinate = dispensary.coordinate else { return nil }
            guard nycOnlyMode == true && dispensary.isNYC == true else {
                return nil
            }
            return DispensaryAnnotation(dispensary: dispensary.toStruct, name: dispensary.name, address: dispensary.fullAddress ?? "", coordinate: coordinate)
        }
    }
    
    var deliveryOnlyDispensaries: [DispensaryCoreData] {
        return dispensaries.filter {
            $0.isTemporaryDeliveryOnly
        }
    }
    
    var dispCounts: DispensaryCounts {
        let allCount = dispensaries.count
        let deliveryOnlyCount = deliveryOnlyDispensaries.count
        let nycAreaCount = dispensaries.filter {$0.isNYC}.count
        
        return DispensaryCounts(
            all: allCount,
            deliveryOnly: deliveryOnlyCount,
            nycArea: nycAreaCount
        )
    }
    
    func loadDataIfNeeded() async throws {
        do {
            try await fetchAndUpdateData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchAndUpdateData() async throws {
        let (dispensariesHTML, fetchedZipCodes) = try await (NetworkManager.shared.fetchDispensaryData(), NetworkManager.shared.fetchAllNYCZipCodes())
        let parsedDispensaries = DataParser.parseDispensaryHTML(dispensariesHTML)
        let nycZipCodes = Set(fetchedZipCodes)
        
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
        fetchDispensaries()
    }
        
    private func loadAddressForDispensary(_ dispensary: DispensaryCoreData) async throws {
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
            Logger.info("Failed to lookup coordinate for '\(fullAddress)' in the map")
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
    
    func selectDispensary(_ dispensary: Dispensary) {
        selectedDispensary = dispensary
        if dispensary.isTemporaryDeliveryOnly {
            // This is currently not possible due to the UI code,
            // however this case should be gracefully handled probably?
            // Maybe I can refactor this out of existence
            return;
        }
        if dispensary.coordinate == nil {
            // This should be rare, but its when we loaded
            // too many dispensaries whose addresses were not in
            // the address cache and we got rate limited while
            // geocoding
            // maybe I can also refactor this out of existence
            return;
        }
        if let annotation = dispensaryAnnotations.first(where: { $0.dispensary.id == dispensary.id }) {
            selectedAnnotation = annotation
            selectedTab = "map"
        }
    }
    
    
}
