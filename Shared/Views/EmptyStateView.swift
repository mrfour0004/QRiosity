//
//  EmptyStateView.swift
//  QRiosity
//
//  Created by Claude on 2024/8/24.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImageName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImageName)
                .font(.system(size: 128, weight: .bold))

            VStack(spacing: 8) {
                Text(title)
                    .font(.avenir(.title2).weight(.black))

                Text(message)
                    .font(.avenir(.body))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 32)
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView(
                title: "No Collected Items",
                message: "Tap the heart icon on any scanned code to add it to your collection.",
                systemImageName: "heart"
            )
            .previewDisplayName("Collected Empty State")

            EmptyStateView(
                title: "No Scan History",
                message: "Start scanning QR codes and barcodes to see your history here.",
                systemImageName: "clock"
            )
            .previewDisplayName("History Empty State")
        }
        .padding()
        .background(Color(.displayP3, white: 0.96, opacity: 1))
    }
}
