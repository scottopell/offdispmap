import SwiftUI
import CoreData
import CoreLocation

struct DeveloperView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Dispensary.name, ascending: true)],
        animation: .default)
    private var dispensaries: FetchedResults<Dispensary>
    
    @State private var uncachedDispensaryCoordinates: String = ""
    @State private var showingCopiedAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    coreDataSection
                    geocodingLogSection
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
        uncachedDispensaryCoordinates = logUncachedCoordinates(Array(dispensaries), onlyNonCached: true)
    }
    
    private var coreDataSection: some View {
        HStack {
            Button("Delete All Data") {
                deleteAllData()
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

    private var dispensaryDebugSection: some View {
        VStack(alignment: .leading) {
            Text("Dispensary Debug Info").font(.headline)
            ForEach(dispensaries, id: \.name) { dispensary in
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
    
    private func deleteAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Dispensary")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
}

func logUncachedCoordinates(_ dispensaries: [Dispensary], onlyNonCached: Bool) -> String {
    var log = "let dispensaryCoordinates: [String: CLLocationCoordinate2D] = ["
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
