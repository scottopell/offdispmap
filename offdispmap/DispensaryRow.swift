//
//  DispensaryRow.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//
import Foundation
import SafariServices
import SwiftUI

@MainActor
struct DispensaryRow: View {
    var dispensary: Dispensary
    var isSelected: Bool = false
    var onSelect: () -> Void
    
    @State private var presentSafari = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                    Text(dispensary.name)
                        .fontWeight(.bold)
                }
                if let address = dispensary.address, let city = dispensary.city, let zipCode = dispensary.zipCode {
                    HStack {
                        Image(systemName: "map")
                            .foregroundColor(.green)
                        Text("\(address), \(city), \(zipCode)")
                    }
                } else if let city = dispensary.city {
                    HStack {
                        Image(systemName: "map")
                            .foregroundColor(.green)
                        Text("\(city)")
                    }
                }
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    if dispensary.url != nil {
                        Text(dispensary.website)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                presentSafari = true
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
                        if !dispensary.isTemporaryDeliveryOnly {
                            Image(systemName: "location.magnifyingglass").foregroundColor(.blue)
                        }
                    }
                }
                .onTapGesture {
                    onSelect()
                }
            }
        }
        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .background(
            EmptyView().sheet(isPresented: $presentSafari) {
                SafariViewController(url: dispensary.url!)
                    .edgesIgnoringSafeArea(.all)
            }
        )
    }
}


struct SafariViewController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariViewController>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariViewController>) {
    }
}
