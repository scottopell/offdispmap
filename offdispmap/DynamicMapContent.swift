//
//  MapViewModel.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation
import SwiftUI
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    @Published var allDispensaries: [Dispensary] = []
    @Published var dispensaryAnnotations: [DispensaryAnnotation] = []
    
    private var dispensaryManager = DispensaryManager()
    
    func loadData() async {
        do {
            (allDispensaries, dispensaryAnnotations) = try await dispensaryManager.fetchAndPrepareData()
        } catch {
            print("Failed to load data: \(error)")
        }
    }
}
