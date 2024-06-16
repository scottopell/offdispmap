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

    // List of NYC zip codes
    private let nycZipCodes: Set<String> = [
        "10001", "10002", "10003", "10004", "10005", "10006", "10007", "10009",
        "10010", "10011", "10012", "10013", "10014", "10016", "10017", "10018",
        "10019", "10020", "10021", "10022", "10023", "10024", "10025", "10026",
        "10027", "10028", "10029", "10030", "10031", "10032", "10033", "10034",
        "10035", "10036", "10037", "10038", "10039", "10040", "10044", "10065",
        "10075", "10128", "10280", "10282", "11101", "11201", "11205", "11211",
        "11215", "11217", "11231"
    ]

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
                Toggle(isOn: $nycOnlyMode) {
                    Text("NYC-only")
                }
                .padding()
            }

            MapView(annotations: $mapViewModel.dispensaryAnnotations, selectedAnnotation: $selectedAnnotation)
            
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
            return mapViewModel.allDispensaries.filter { nycZipCodes.contains($0.zipCode) }
        } else {
            return mapViewModel.allDispensaries
        }
    }

    private func selectDispensary(_ dispensary: Dispensary) {
        selectedDispensary = dispensary
        Task {
            await mapViewModel.loadCoordinates(dispensary: dispensary)
            print("Got coordinates, now looking for dispensary annotation")
            print("All annotations \(mapViewModel.dispensaryAnnotations)")
            if let annotation = mapViewModel.dispensaryAnnotations.first(where: { $0.dispensary == dispensary }) {
                selectedAnnotation = annotation
            }
        }
    }
}

#Preview {
    ContentView()
}
