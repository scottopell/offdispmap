//
//  DispensaryRow.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import Foundation
import SwiftUI

struct DispensaryRow: View {
    var dispensary: Dispensary
    var isSelected: Bool = false
    var onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(dispensary.name).fontWeight(.bold)
                Text(dispensary.address)
                Text("\(dispensary.city), \(dispensary.zipCode)")
                Link(dispensary.website, destination: URL(string: dispensary.website)!)
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                onSelect()
            }) {
                Image(systemName: isSelected ? "xmark.circle.fill" : "location.magnifyingglass")
                    .foregroundColor(isSelected ? .red : .blue)
            }
        }
        .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .padding([.top, .bottom], 5)
    }
}
