//
//  DispensaryRow.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        // No need to update anything here
    }
}


import Foundation
import SwiftUI

@MainActor
struct DispensaryRow: View {
    var dispensary: Dispensary
    var isSelected: Bool = false
    var onSelect: () -> Void
    
    @State private var safariURL: URL?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                    Text(dispensary.name)
                        .fontWeight(.bold)
                }
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.green)
                    Text("\(dispensary.address), \(dispensary.city), \(dispensary.zipCode)")
                }
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    if let url = dispensary.url {
                        Text(dispensary.website)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                safariURL = url
                            }
                    } else {
                        Text(dispensary.website)
                            .foregroundColor(.gray)
                    }
                }
                
            }
            Spacer()
            VStack {
                Group {
                    if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    } else {
                        Image(systemName: "location.magnifyingglass").foregroundColor(.blue)
                    }
                }
                .onTapGesture {
                    onSelect()
                }
            }
        }
        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .sheet(isPresented: Binding<Bool>(
            get: { safariURL != nil },
            set: { newValue in
                if !newValue {
                    safariURL = nil
                }
            }
        )) {
            if let url = safariURL {
                SafariView(url: url)
            } else {
                Text("No URL provided")
            }
        }
    }
}

