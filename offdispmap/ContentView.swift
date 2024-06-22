import SwiftUI
import MapKit

@MainActor
struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @State private var selectedDispensary: Dispensary?
    @State private var selectedAnnotation: DispensaryAnnotation?
    @State private var hasFetched = false
    @State private var isFetching = false
    @State private var nycOnlyMode = true
    
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

    var body: some View {
        VStack(spacing: 20) {
            Text("NY Dispensaries")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                if !hasFetched {
                    Button(action: {
                        Task {
                            isFetching = true
                            await mapViewModel.loadData()
                            hasFetched = true
                            isFetching = false
                        }
                    }) {
                        Text(isFetching ? "Fetching..." : "Fetch Data")
                            .foregroundColor(.white)
                            .padding()
                            .background(isFetching ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                }
                Button {
                    Task {
                        Logger.info("Doing 1 geocode")
                        if let disp = await loadLocations(n: 1) {
                            selectDispensary(disp)
                        }
                    }
                } label: {
                    Text("Load 1")
                }
                Button {
                    Task {
                        Logger.info("Doing 5 geocode")
                        if let disp = await loadLocations(n: 5) {
                            selectDispensary(disp)
                        }
                    }
                } label: {
                    Text("Load 5")
                }

                Toggle(isOn: $nycOnlyMode) {
                    Text("NYC-only")
                }
                .padding()
            }

            MapView(annotations: $mapViewModel.dispensaryAnnotations, selectedAnnotation: $selectedAnnotation, nycOnlyMode: $nycOnlyMode)
            
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
