import SwiftUI
import MapKit
import CoreLocation
import CoreData

struct StatCard: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 20, idealWidth: 40, maxWidth: 80, minHeight: 30, idealHeight: 40)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 2)
    }
}


struct DispensaryCounts {
    var all: Int
    var deliveryOnly: Int
    var nycArea: Int
}

struct WarningNotice: View {
    let warningMsg: String
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .imageScale(.large)
            Text(warningMsg)
                .foregroundColor(.primary)
                .font(.body)
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}



struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Dispensary.name, ascending: true)],
        animation: .default)
    private var dispensaries: FetchedResults<Dispensary>
    
    @State private var selectedDispensary: Dispensary?
    @State private var selectedAnnotation: DispensaryAnnotation?
    @State private var hasFetched = false
    @State private var isLoading = false
    @State private var nycOnlyMode = true
    @State private var deliveryOnlyMode = false
    @State private var selectedTab = "map"
    @State private var errorMessage: String?
    #if DEBUG
    @State private var showDeveloperView = false
    #endif


    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 10) {
                headerView
                if let err = errorMessage {
                    WarningNotice(warningMsg: err)
                }
                if isLoading {
                    fetchingDataView
                    Spacer()
                } else {
                    mapView
                    statisticsView
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
                if let err = errorMessage {
                    WarningNotice(warningMsg: err)
                }
                if isLoading {
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
        }
        #if DEBUG
        .sheet(isPresented: $showDeveloperView) {
            DeveloperView()
                .environment(\.managedObjectContext, viewContext)
        }
        #endif
        .onAppear {
            let _ = LocationManager.shared
            loadDataIfNeeded()
        }
    }
    private var headerView: some View {
        let place = nycOnlyMode ? "NYC" : "NY"
        return Text(place + " Dispensaries")
            .font(.title)
            .fontWeight(.bold)
    }

    private var statisticsView: some View {
        HStack() {
            HStack() {
                ForEach([
                    ("NYC", dispCounts.nycArea),
                    ("Delivery", dispCounts.deliveryOnly),
                    ("Total", dispCounts.all)
                ], id: \.0) { label, value in
                    StatCard(label: label, value: value)
                }
            }
            Spacer()
            HStack() {
                Toggle("NYC Only", isOn: $nycOnlyMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue)).fixedSize()
                #if DEBUG
                Button(action: { showDeveloperView = true }) {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.blue)
                }
                .padding(.leading, 10)
                #endif
            }.lineLimit(1)
        }
        .padding(5)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }


    private var fetchingDataView: some View {
        Text("Loading data from https://cannabis.ny.gov/dispensary-location-verification...")
    }

    private var mapView: some View {
        MapView(
            annotations: dispensaryAnnotations,
            selectedAnnotation: selectedAnnotation,
            annotationFilter: { annotation in
                    (self.nycOnlyMode ? annotation.dispensary.isNYC : true)
            },
            onAnnotationSelect: { annotation in
                selectDispensary(annotation.dispensary)
            })
    }

    private var selectedDispensaryView: some View {
        Group {
            if let currentlySelectedDispensary = selectedDispensary {
                DispensaryRow(dispensary: currentlySelectedDispensary, isSelected: true) {
                    selectedDispensary = nil
                    selectedAnnotation = nil
                }.padding(5)
            }
        }
    }

    private var dispensaryListView: some View {
        let displayDispensaries = dispensaries.filter { dispensary in
            if deliveryOnlyMode && dispensary.isTemporaryDeliveryOnly == false {
                return false
            }
            if nycOnlyMode && dispensary.isNYC == false {
                return false
            }
            return true
        }
        return VStack {
            Toggle(isOn: $deliveryOnlyMode) {
                Text("Delivery Only")
            }
            if deliveryOnlyMode {
                WarningNotice(warningMsg: "Who knows where these places deliver to? Just because its listed here doesn't mean it delivers to you. Duh.")
            }
            List(displayDispensaries, id: \.name) { dispensary in
                DispensaryRow(dispensary: dispensary, isSelected: dispensary == selectedDispensary) {
                    selectDispensary(dispensary)
                }
            }.listStyle(.plain)
        }
    }
    
    private var dispensaryAnnotations: [DispensaryAnnotation] {
        dispensaries.compactMap { dispensary in
            guard let coordinate = dispensary.coordinate else { return nil }
            guard nycOnlyMode == true && dispensary.isNYC == true else {
                return nil
            }
            return DispensaryAnnotation(dispensary: dispensary, name: dispensary.name, address: dispensary.fullAddress ?? "", coordinate: coordinate)
        }
    }
    
    private func loadDataIfNeeded() {
        // TODO, if data has been recently fetched, then skip this
        Task {
            do {
                try await fetchAndUpdateData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func fetchAndUpdateData() async throws {
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
                
            try? viewContext.save()
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
    
    private var dispCounts: DispensaryCounts {
        let allCount = dispensaries.count
        let deliveryOnlyCount = deliveryOnlyDispensaries.count
        let nycAreaCount = dispensaries.filter {$0.isNYC}.count
        
        return DispensaryCounts(
            all: allCount,
            deliveryOnly: deliveryOnlyCount,
            nycArea: nycAreaCount
        )
    }
    
    private var deliveryOnlyDispensaries: [Dispensary] {
        return dispensaries.filter {
            $0.isTemporaryDeliveryOnly
        }
    }

    private func selectDispensary(_ dispensary: Dispensary) {
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
        Task {
            if let annotation = dispensaryAnnotations.first(where: { $0.dispensary == dispensary }) {
                selectedAnnotation = annotation
                selectedTab = "map"
            }
        }
    }
}

#Preview {
    ContentView()
}
