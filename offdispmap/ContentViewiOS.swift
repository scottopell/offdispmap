//
//  ContentViewiOS.swift
//  offdispmap
//
//  Created by Brian Floersch on 7/13/24.
//

import Foundation
import SwiftUI
import CoreData



struct ContentViewiOS: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DispensaryCoreData.name, ascending: true)],
        animation: .default)
    private var dispensaries: FetchedResults<DispensaryCoreData>
    
    @State private var selectedDispensary: Dispensary?
    @State private var selectedAnnotation: DispensaryAnnotation?
    @State var displayDispensaries: [Dispensary] = []
    @State private var hasFetched = false
    @State private var isLoading = false
    @State private var nycOnlyMode = true
    @State private var deliveryOnlyMode = false
    @State private var selectedTab = "map"
    @State private var errorMessage: String?
    @State private var selectedDetent = PresentationDetent.fraction(0.25)
    
    #if DEBUG
    @State private var showDeveloperView = false
    #endif
    
    private var headerTitle: String {
        let place = nycOnlyMode ? "NYC" : "NY"
        return "\(place) Dispensaries"
    }
    
    private var dispensaryAnnotations: [DispensaryAnnotation] {
        dispensaries.compactMap { dispensary in
            guard let coordinate = dispensary.coordinate else { return nil }
            guard nycOnlyMode == true && dispensary.isNYC == true else {
                return nil
            }
            return DispensaryAnnotation(dispensary: dispensary.toStruct, name: dispensary.name, address: dispensary.fullAddress ?? "", coordinate: coordinate)
        }
    }
    
    private var deliveryOnlyDispensaries: [DispensaryCoreData] {
        return dispensaries.filter {
            $0.isTemporaryDeliveryOnly
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
    
    private var statisticsView: some View {
        VStack {
            HStack() {
                ForEach([
                    ("NYC", dispCounts.nycArea),
                    ("Delivery", dispCounts.deliveryOnly),
                    ("Total", dispCounts.all)
                ], id: \.0) { label, value in
                    StatCard(label: label, value: value)
                }
            }
            Divider()
            HStack() {
                HStack() {
                    Text("NYC Only")
                    Spacer()
                    Toggle("", isOn: $nycOnlyMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue)).fixedSize()
                }.lineLimit(1)
            }
            Divider()
            Toggle(isOn: $deliveryOnlyMode) {
                Text("Delivery Only")
            }
            
            if deliveryOnlyMode {
                WarningNotice(warningMsg: "Who knows where these places deliver to? Just because its listed here doesn't mean it delivers to you. Duh.")
            }
#if DEBUG
            Divider()
            HStack {
                Text("Developer")
                Spacer()
                Button(action: { showDeveloperView = true }) {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.blue)
                }
            }
#endif
        }
    }
    
    private var dispensaryListView: some View {
        
        return LazyVStack {
            ForEach(displayDispensaries, id: \.name) { dispensary in
                Button(action: {
                    selectDispensary(dispensary)
                    selectedDetent = .fraction(0.25)
                }) {
                    DispensaryRow(dispensary: dispensary, isSelected: dispensary.id == selectedDispensary?.id)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                Divider()

            }.listStyle(.plain)
        }
    }
    
    var body: some View {
            MapView(
                annotations: dispensaryAnnotations,
                selectedAnnotation: selectedAnnotation,
                annotationFilter: { annotation in
                    (self.nycOnlyMode ? annotation.dispensary.isNYC : true)
                },
                onAnnotationSelect: { annotation in
                    selectDispensary(annotation.dispensary)
                })
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                ScrollView {
                    VStack {
                        HStack {
                            Text(headerTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        statisticsView
                            .padding(.horizontal)
                        Divider()
                        
                        dispensaryListView
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .presentationDetents([.fraction(0.25), .medium], selection: $selectedDetent)
                            .presentationBackgroundInteraction(.enabled)
                            .interactiveDismissDisabled()
                            .presentationBackground(.thinMaterial)
                    }
                }
            }
            .onAppear {
                if displayDispensaries.isEmpty { // So the preview works
                    reload()
                }
            }
            .onChange(of: nycOnlyMode) {
                reload()
            }
            .onChange(of: deliveryOnlyMode) {
                reload()
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
            if let annotation = dispensaryAnnotations.first(where: { $0.dispensary.id == dispensary.id }) {
                selectedAnnotation = annotation
                selectedTab = "map"
            }
        }
    }
    
    func reload() {
        displayDispensaries = dispensaries.filter { dispensary in
            if deliveryOnlyMode && dispensary.isTemporaryDeliveryOnly == false {
                return false
            }
            if nycOnlyMode && dispensary.isNYC == false {
                return false
            }
            return true
        }.map { $0.toStruct }
    }
}

#Preview {
    ContentViewiOS(displayDispensaries: [
        Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
        Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
        Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
        Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil),
        Dispensary(name: "foo", website: "bar", latitude: 0, longitude: 0, isTemporaryDeliveryOnly: true, isNYC: true, url: nil, fullAddress: nil)
    ])
}
