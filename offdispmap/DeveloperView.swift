//
//  DeveloperView.swift
//  offdispmap
//
//  Created by Scott Opell on 6/29/24.
//

import Foundation
import SwiftUI

func logUncachedCoordinates(_ dispensaries: [Dispensary], onlyNonCached: Bool) -> String {
    var log = "let dispensaryCoordinates: [String: CLLocationCoordinate2D] = [\""
    for dispensary in dispensaries {
        if let coordinate = dispensary.coordinate, let fullAddress = dispensary.fullAddress {
            if DispensaryData.shared.getCoordinate(for: fullAddress) == nil {
                log += "\"\(fullAddress)\": CLLocationCoordinate2D(latitude: \(coordinate.latitude), longitude: \(coordinate.longitude)),\n"
            }
        }
    }
    log += "]"
    return log
}

struct DeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var mapViewModel: MapViewModel
    @State private var uncachedDispensaryCoordinates: String = ""
    @State private var nycZipCodes: String = ""
    @State private var showingCopiedAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    geocodingLogSection
                    zipCodesSection
                    dispensaryDebugSection
                }
                .padding()
            }
            .navigationTitle("Developer View")
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            })
        }
        .alert("Copied to Clipboard", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        uncachedDispensaryCoordinates = logUncachedCoordinates(mapViewModel.allDispensaries, onlyNonCached: true)
        Task {
            do {
                let zipCodes = try await NetworkManager.shared.fetchAllNYCZipCodes()
                nycZipCodes = zipCodes.sorted().map({ "\"\($0)\"" }).joined(separator: ", ")
            } catch {
                print("Error fetching NYC zip codes: \(error)")
                nycZipCodes = "<error fetching: \(error)>"
            }
        }
    }
    
    private var geocodingLogSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Geocoding Results not in source cache").font(.headline)
                Spacer()
                Button("Copy All") {
                    UIPasteboard.general.string = uncachedDispensaryCoordinates
                    showingCopiedAlert = true
                }
            }
            TextEditor(text: .constant(uncachedDispensaryCoordinates))
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .border(Color.gray, width: 1)
        }
    }

    private var zipCodesSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("NYC Zip Codes").font(.headline)
                Spacer()
                Button("Copy All") {
                    UIPasteboard.general.string = nycZipCodes
                    showingCopiedAlert = true
                }
            }
            TextEditor(text: .constant(nycZipCodes))
                .font(.system(.body, design: .monospaced))
                .frame(height: 100)
                .border(Color.gray, width: 1)
        }
    }

    private var dispensaryDebugSection: some View {
        VStack(alignment: .leading) {
            Text("Dispensary Debug Info").font(.headline)
            ForEach(mapViewModel.allDispensaries, id: \.name) { dispensary in
                VStack(alignment: .leading) {
                    Text(dispensary.name).font(.subheadline)
                    if let fullAddress = dispensary.fullAddress {
                        Text(fullAddress).font(.caption)
                    }
                    if let coordinate = dispensary.coordinate {
                        Text("Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
                            .font(.caption)
                    } else if !dispensary.isTemporaryDeliveryOnly {
                        Text("Coordinate not available")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
