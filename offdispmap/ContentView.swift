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
        .background(Color(UIColor.systemBackground).opacity(0.4))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}



struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: MainViewModel
    
    #if DEBUG
    @State private var showDeveloperView = false
    #endif


    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            VStack(spacing: 10) {
                headerView
                if let err = viewModel.errorMessage {
                    WarningNotice(warningMsg: err)
                }
                if viewModel.isLoading {
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
                if let err = viewModel.errorMessage {
                    WarningNotice(warningMsg: err)
                }
                if viewModel.isLoading {
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
            if viewModel.displayDispensaries.isEmpty { // So mock data works in the preview
                Task { @MainActor in
                    try await viewModel.fetchAndUpdateData()
                }
            }
        }
    }
    private var headerView: some View {
        let place = viewModel.nycOnlyMode ? "NYC" : "NY"
        return Text(place + " Dispensaries")
            .font(.title)
            .fontWeight(.bold)
    }

    private var statisticsView: some View {
        HStack() {
            HStack() {
                ForEach([
                    ("NYC", viewModel.dispCounts.nycArea),
                    ("Delivery", viewModel.dispCounts.deliveryOnly),
                    ("Total", viewModel.dispCounts.all)
                ], id: \.0) { label, value in
                    StatCard(label: label, value: value)
                }
            }
            Spacer()
            HStack() {
                Toggle("NYC Only", isOn: $viewModel.nycOnlyMode)
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
            annotations: viewModel.dispensaryAnnotations,
            selectedAnnotation: viewModel.selectedAnnotation,
            annotationFilter: { annotation in
                (viewModel.nycOnlyMode ? annotation.dispensary.isNYC : true)
            },
            onAnnotationSelect: { annotation in
                viewModel.selectDispensary(annotation.dispensary)
            })
    }

    private var selectedDispensaryView: some View {
        Group {
            if let currentlySelectedDispensary = viewModel.selectedDispensary {
                DispensaryRow(dispensary: currentlySelectedDispensary, isSelected: true) {
                    viewModel.selectedDispensary = nil
                    viewModel.selectedAnnotation = nil
                }.padding(5)
            }
        }
    }

    private var dispensaryListView: some View {
        return VStack {
            Toggle(isOn: $viewModel.deliveryOnlyMode) {
                Text("Delivery Only")
            }
            if viewModel.deliveryOnlyMode {
                WarningNotice(warningMsg: "Who knows where these places deliver to? Just because its listed here doesn't mean it delivers to you. Duh.")
            }
            List(viewModel.displayDispensaries, id: \.name) { dispensary in
                DispensaryRow(dispensary: dispensary, isSelected: dispensary.id == viewModel.selectedDispensary?.id) {
                    viewModel.selectDispensary(dispensary)
                }
            }.listStyle(.plain)
        }
    }
    
}

#Preview {
    ContentView(viewModel: {
        let vm = MainViewModel()
        vm.displayDispensaries = [
            Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
            Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
            Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
            Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
            Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil)
        ]
        return vm
    }())
}
