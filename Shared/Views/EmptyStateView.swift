//
//  EmptyStateView.swift
//  QRiosity
//
//  Created by Claude on 2024/8/24.
//

import SwiftUI

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 24) {
            Color.clear
                .glassEffect(.clear, in: BarcodeShape())
                .frame(width: 180, height: 124)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(spacing: 8) {
                Text(title)
                    .font(.avenir(.title2).weight(.black))

                Text(message)
                    .font(.avenir(.body))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 32)
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView(
                title: "No records, yet!",
                message: "Tap the heart icon on any scanned code to add it to your collection."
            )
            .previewDisplayName("Collected Empty State")

            EmptyStateView(
                title: "No Scan History",
                message: "Start scanning QR codes and barcodes to see your history here."
            )
            .previewDisplayName("History Empty State")
        }
    }
}
