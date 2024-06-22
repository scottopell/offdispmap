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
    @State private var deliveryOnlyMode = false
    @State private var selectedTab = "map"

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 20) {
                headerView
                statisticsView
                if isFetching {
                    fetchingDataView
                    Spacer()
                } else {
                    mapView
                    selectedDispensaryView
                }
            }
            .padding()
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag("map")

            VStack(spacing: 20) {
                headerView
                statisticsView
                if isFetching {
                    fetchingDataView
                    Spacer()
                } else {
                    dispensaryListView
                }
            }
            .padding()
            .tabItem {
                Label("List", systemImage: "list.bullet")
            }
            .tag("list")
            
            VStack(spacing: 20) {
                headerView
                settingsView
            }
            .padding()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag("settings")
        }
        .onAppear {
            fetchDataIfNeeded()
        }
    }
    private var headerView: some View {
        let place = nycOnlyMode ? "NYC" : "NY"
        return Text(place + " Dispensaries")
            .font(.title)
            .fontWeight(.bold)
    }

    private var statisticsView: some View {
        HStack {
            Text("NYC Area: \(dispCounts.nycArea)")
            Spacer()
            Text("Delivery-Only: \(dispCounts.deliveryOnly)")
            Spacer()
            Text("Total: \(dispCounts.all)")
        }
    }

    private var fetchingDataView: some View {
        Text("Loading data from https://cannabis.ny.gov/dispensary-location-verification...")
    }

    private var controlsView: some View {
        HStack {
            if dispCounts.locationLess > 0 {
                Button(action: loadMissingCoordinates) {
                    Text("Load missing location data")
                }
            }
            Toggle(isOn: $nycOnlyMode) {
                Text("NYC-only")
            }
            .padding()
        }
    }

    private var mapView: some View {
        MapView(annotations: $mapViewModel.dispensaryAnnotations, selectedAnnotation: $selectedAnnotation, nycOnlyMode: $nycOnlyMode,            onAnnotationSelect: { annotation in
            selectDispensary(annotation.dispensary)
        })
    }

    private var selectedDispensaryView: some View {
        Group {
            if let currentlySelectedDispensary = selectedDispensary {
                DispensaryRow(dispensary: currentlySelectedDispensary, isSelected: true) {
                    selectedDispensary = nil
                    selectedAnnotation = nil
                }
            }
        }
    }

    private var dispensaryListView: some View {
        VStack {
            Toggle(isOn: $deliveryOnlyMode) {
                Text("Delivery-Only")
            }
            .padding()
            List(deliveryOnlyMode ? mapViewModel.allDispensaries.filter { $0.isTemporaryDeliveryOnly } : filteredDispensaries, id: \.name) { dispensary in
                DispensaryRow(dispensary: dispensary, isSelected: dispensary == selectedDispensary) {
                    selectDispensary(dispensary)
                }
            }
        }
    }
    
    private var settingsView: some View {
        VStack {
            HStack {
                Text("Total: \(dispCounts.all)")
                Text("Delivery-Only: \(dispCounts.deliveryOnly)")
                Text("NYC Area: \(dispCounts.nycArea)")
                Text("Location-Less: \(dispCounts.locationLess)")
            }
            controlsView
            Spacer()
        }
    }
    
    private func fetchDataIfNeeded() {
        if hasFetched {
            return
        }
        isFetching = true
        Task {
            await mapViewModel.loadData()
            hasFetched = true
            isFetching = false
        }
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
    
    private func loadMissingCoordinates() {
        Task {
            if let disp = await loadLocations(n: 1) {
                selectDispensary(disp)
            }
        }
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
                selectedTab = "map"
            }
        }
    }
}

#Preview {
    ContentView()
}
