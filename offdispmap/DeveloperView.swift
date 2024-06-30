//
//  DeveloperView.swift
//  offdispmap
//
//  Created by Scott Opell on 6/29/24.
//

import Foundation
import SwiftUI

struct DeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var mapViewModel: MapViewModel
    @State private var geocodingLog: String = ""
    @State private var newGeocodingLog: String = ""
    @State private var nycZipCodes: String = ""
    @State private var showingCopiedAlert = false

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding()
                }
                Spacer()
            }.frame(alignment: .topLeading)
        }
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    geocodingLogSection
                    newGeocodingResultsSection
                    zipCodesSection
                    dispensaryDebugSection
                }
                .padding()
            }
            .navigationTitle("Developer View")
        }
        .alert("Copied to Clipboard", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        geocodingLog = mapViewModel.logCoordinates(onlyNonCached: false)
        newGeocodingLog = mapViewModel.logCoordinates(onlyNonCached: true)
        Task {
            do {
                let zipCodes = try await fetchAllNYCZipCodes()
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
                Text("Geocoding Log").font(.headline)
                Spacer()
                Button("Copy All") {
                    UIPasteboard.general.string = geocodingLog
                    showingCopiedAlert = true
                }
            }
            if !geocodingLog.isEmpty {
                TextEditor(text: .constant(geocodingLog))
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
            }
        }
    }
    
    private var newGeocodingResultsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("New Geocoding Results").font(.headline)
                Spacer()
                Button("Copy All") {
                    UIPasteboard.general.string = newGeocodingLog
                    showingCopiedAlert = true
                }
            }
            TextEditor(text: .constant(newGeocodingLog))
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
                    } else {
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
