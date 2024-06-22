import SwiftUI
import MapKit

struct DispensaryCounts {
    var all: Int
    var locationLess: Int
    var deliveryOnly: Int
    var nycArea: Int
}

@MainActor
struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @State private var selectedDispensary: Dispensary?
    @State private var selectedAnnotation: DispensaryAnnotation?
    @State private var hasFetched = false
    @State private var isFetching = false
    @State private var nycOnlyMode = true
    

    var body: some View {
        VStack(spacing: 20) {
            Text("NY Dispensaries")
                .font(.title)
                .fontWeight(.bold)
            VStack {
               Text("Total Dispensaries: \(dispCounts.all)")
               Text("Location-Less Dispensaries: \(dispCounts.locationLess)")
               Text("Delivery-Only Dispensaries: \(dispCounts.deliveryOnly)")
               Text("NYC Area Dispensaries: \(dispCounts.nycArea)")
           }
            if isFetching {
                Text("Loading data from https://cannabis.ny.gov/dispensary-location-verification...")
            }
            
            HStack {
                if dispCounts.locationLess > 0 {
                    Button {
                        Task {
                            if let disp = await loadLocations(n: 1) {
                                selectDispensary(disp)
                            }
                        }
                    } label: {
                        Text("Load missing coordinates")
                    }
                }

                Toggle(isOn: $nycOnlyMode) {
                    Text("NYC-only")
                }
                .padding()
            }

            MapView(annotations: $mapViewModel.dispensaryAnnotations, selectedAnnotation: $selectedAnnotation, nycOnlyMode: $nycOnlyMode).onAppear {
                Task {
                    if !hasFetched {
                        isFetching = true
                        await mapViewModel.loadData()
                        hasFetched = true
                        isFetching = false
                    }
                }
            }
            
            if let currentlySelectedDispensary = selectedDispensary {
                DispensaryRow(dispensary: currentlySelectedDispensary, isSelected: true) {
                    selectedDispensary = nil
                    selectedAnnotation = nil
                }
            }
            List(filteredDispensaries.filter { $0 != selectedDispensary }, id: \.name) { dispensary in
                DispensaryRow(dispensary: dispensary) {
                    selectDispensary(dispensary)
                }
            }
        }
        .padding()
    }
    
    
    var dispCounts: DispensaryCounts {
        let nycZipCodes = DispensaryData.shared.nycZipCodes
        
        let allCount = mapViewModel.allDispensaries.count
        let locationLessCount = mapViewModel.allDispensaries.filter { !$0.isTemporaryDeliveryOnly && $0.coordinate == nil }.count
        let deliveryOnlyCount = mapViewModel.allDispensaries.filter { $0.isTemporaryDeliveryOnly }.count
        let nycAreaCount = mapViewModel.allDispensaries.filter { nycZipCodes.contains($0.zipCode) }.count
        
        return DispensaryCounts(
            all: allCount,
            locationLess: locationLessCount,
            deliveryOnly: deliveryOnlyCount,
            nycArea: nycAreaCount
        )
    }
    
    private func loadLocations(n: Int) async -> Dispensary? {
        var lastLoaded: Dispensary?
        for _ in 0..<n {
            if let locationlessDispensary = mapViewModel.allDispensaries.first(where: { $0.isTemporaryDeliveryOnly == false && $0.coordinate == nil }) {
                Logger.info("Loading coordinates for \(locationlessDispensary)")
                // Use the wrapped value to load coordinates
                await mapViewModel.loadCoordinates(dispensary: locationlessDispensary)
                lastLoaded = locationlessDispensary
            }
        }
        return lastLoaded
    }

    private var filteredDispensaries: [Dispensary] {
        if nycOnlyMode {
            return mapViewModel.allDispensaries.filter { DispensaryData.shared.nycZipCodes.contains($0.zipCode) }
        } else {
            return mapViewModel.allDispensaries
        }
    }

    private func selectDispensary(_ dispensary: Dispensary) {
        if nycOnlyMode {
            if !DispensaryData.shared.nycZipCodes.contains(dispensary.zipCode) {
                return
            }
        }
        selectedDispensary = dispensary
        Task {
            await mapViewModel.loadCoordinates(dispensary: dispensary)
            if let annotation = mapViewModel.dispensaryAnnotations.first(where: { $0.dispensary == dispensary }) {
                selectedAnnotation = annotation
            }
        }
    }
}

#Preview {
    ContentView()
}
