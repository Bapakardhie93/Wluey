// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI

struct FlexibleGrid: View {
    
    let items: [String]
    @Binding var selectedItems: Set<String>
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items, id: \.self) { item in
                let isSelected = selectedItems.contains(item)
                
                Text(item)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ?
                        Color.black :
                        Color.gray.opacity(0.2)
                    )
                    .foregroundColor(
                        isSelected ? .white : .black
                    )
                    .cornerRadius(12)
                    .onTapGesture {
                        if isSelected {
                            selectedItems.remove(item)
                        } else {
                            selectedItems.insert(item)
                        }
                    }
            }
        }
    }
}
