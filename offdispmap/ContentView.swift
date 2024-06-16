//
//  ContentView.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import SwiftUI
import MapKit



@MainActor
struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @State private var selectedAnnotation: DispensaryAnnotation?
    
    
    @State private var isFetching = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dispensary Data Fetcher")
                .font(.title)
                .fontWeight(.bold)
            
            Button(action: {
                Task {
                    isFetching = true
                    await mapViewModel.loadData()
                    isFetching = false
                }
            }) {
                Text(isFetching ? "Fetching..." : "Fetch Data")
                    .foregroundColor(.white)
                    .padding()
                    .background(isFetching ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            
            MapView(annotations: $mapViewModel.dispensaryAnnotations, selectedAnnotation: $selectedAnnotation)
            
            List(mapViewModel.allDispensaries, id: \.name) { dispensary in
                HStack() {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(dispensary.name).fontWeight(.bold)
                        Text(dispensary.address)
                        Text("\(dispensary.city), \(dispensary.zipCode)")
                        Link(dispensary.website, destination: URL(string: dispensary.website)!)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button(action: {
                        print("Navigate to \(dispensary.name)")
                        selectDispensary(dispensary)
                    }) {
                        Image(systemName: "location.magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }

            }
        }
        .padding()
    }
    private func selectDispensary(_ dispensary: Dispensary) {
        if let annotation = mapViewModel.dispensaryAnnotations.first(where: { $0.title == dispensary.name }) {
            selectedAnnotation = annotation
        }
    }
}


#Preview {
    ContentView()
}
