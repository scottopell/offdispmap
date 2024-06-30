import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Handle the authorization status change
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // Handle denied or restricted status
            break
        default:
            break
        }
    }
}

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
    @State private var showDeveloperView = false


    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 10) {
                headerView
                if let err = mapViewModel.errorMessage {
                    WarningNotice(warningMsg: err)
                }
                if isFetching {
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
                if let err = mapViewModel.errorMessage {
                    WarningNotice(warningMsg: err)
                }
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
        }
        .sheet(isPresented: $showDeveloperView) {
            DeveloperView(mapViewModel: mapViewModel)
        }
        .onAppear {
            let _ = LocationManager()
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
                Button(action: { showDeveloperView = true }) {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.blue)
                }
                .padding(.leading, 10)
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
        MapView(annotations: $mapViewModel.dispensaryAnnotations, selectedAnnotation: $selectedAnnotation, annotationFilter: Binding(
            get: {
                { annotation in
                    (self.nycOnlyMode ? annotation.dispensary.isNYC : true)
                }
            },
            set: { _ in }
        ),            onAnnotationSelect: { annotation in
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
        VStack {
            Toggle(isOn: $deliveryOnlyMode) {
                Text("Delivery Only")
            }
            if deliveryOnlyMode {
                WarningNotice(warningMsg: "Who knows where these places deliver to? Just because its listed here doesn't mean it delivers to you. Duh.")
            }
            List(deliveryOnlyMode ? deliveryOnlyDispensaries : filteredDispensaries, id: \.name) { dispensary in
                DispensaryRow(dispensary: dispensary, isSelected: dispensary == selectedDispensary) {
                    selectDispensary(dispensary)
                }
            }.listStyle(.plain)
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
        let allCount = mapViewModel.allDispensaries.count
        let deliveryOnlyCount = deliveryOnlyDispensaries.count
        let nycAreaCount = mapViewModel.allDispensaries.filter {$0.isNYC}.count
        
        return DispensaryCounts(
            all: allCount,
            deliveryOnly: deliveryOnlyCount,
            nycArea: nycAreaCount
        )
    }
    
    private var filteredDispensaries: [Dispensary] {
        if nycOnlyMode {
            return mapViewModel.allDispensaries.filter {$0.isNYC }
        } else {
            return mapViewModel.allDispensaries
        }
    }
    
    private var deliveryOnlyDispensaries: [Dispensary] {
        return mapViewModel.allDispensaries.filter {
            $0.isTemporaryDeliveryOnly
        }
    }

    private func selectDispensary(_ dispensary: Dispensary) {
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
