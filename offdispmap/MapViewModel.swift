//
//  MapViewModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation

@MainActor
class MapViewModel: ObservableObject {
    @Published var allDispensaries: [Dispensary] = []
    @Published var dispensaryAnnotations: [DispensaryAnnotation] = []
    @Published var nycZipCodes: Set<String> = []
    @Published var errorMessage: String? = nil
        
    func loadData() async {
        do {
            async let dispensariesTask = NetworkManager.shared.fetchDispensaryData()
            async let zipCodesTask = NetworkManager.shared.fetchAllNYCZipCodes()
            
            let (dispensaryHTML, fetchedZipCodes) = try await (dispensariesTask, zipCodesTask)
            allDispensaries = DataParser.parseDispensaryHTML(dispensaryHTML)
            nycZipCodes = Set(fetchedZipCodes)
            for dispensary in allDispensaries {
                if let zipCode = dispensary.zipCode {
                    let isNYC = nycZipCodes.contains(where: {$0 == zipCode})
                    dispensary.isNYC = isNYC
                }
                if let fullAddress = dispensary.fullAddress {
                    dispensary.coordinate = DispensaryData.shared.getCoordinate(for: fullAddress)
                }
                if dispensary.coordinate == nil {
                    await dispensary.populateCoordinate()
                }
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
