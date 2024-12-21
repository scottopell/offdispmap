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
    
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedDetent = PresentationDetent.fraction(0.25)
    
    #if DEBUG
    @State private var showDeveloperView = false
    #endif
    
    
    private var statisticsView: some View {
        VStack {
            HStack() {
                ForEach([
                    ("NYC", viewModel.dispCounts.nycArea),
                    ("Delivery", viewModel.dispCounts.deliveryOnly),
                    ("Total", viewModel.dispCounts.all)
                ], id: \.0) { label, value in
                    StatCard(label: label, value: value)
                }
            }
            Divider()
            HStack() {
                HStack() {
                    Text("NYC Only")
                    Spacer()
                    Toggle("", isOn: $viewModel.nycOnlyMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue)).fixedSize()
                }.lineLimit(1)
            }
            Divider()
            Toggle(isOn: $viewModel.deliveryOnlyMode) {
                Text("Delivery Only")
            }
            
            if viewModel.deliveryOnlyMode {
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
            ForEach(viewModel.displayDispensaries) { dispensary in
                Button(action: {
                    viewModel.selectDispensary(dispensary)
                    selectedDetent = .fraction(0.25)
                }) {
                    DispensaryRow(dispensary: dispensary, isSelected: dispensary.id == viewModel.selectedDispensary?.id)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                Divider()

            }.listStyle(.plain)
        }
    }
    
    var body: some View {
            MapView(
                annotations: viewModel.dispensaryAnnotations,
                selectedAnnotation: viewModel.selectedAnnotation,
                annotationFilter: { annotation in
                    (viewModel.nycOnlyMode ? annotation.dispensary.isNYC : true)
                },
                onAnnotationSelect: { annotation in
                    viewModel.selectDispensary(annotation.dispensary)
                })
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                ScrollView {
                    VStack {
                        HStack {
                            Text(viewModel.headerTitle)
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
                let _ = LocationManager.shared
                if viewModel.displayDispensaries.isEmpty { // So mock data works in the preview
                    Task { @MainActor in
                        try await viewModel.fetchAndUpdateData()
                    }
                }
            }
    }
}

#Preview {
    ContentViewiOS(viewModel: {
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
