//
//  BarcodeShape.swift
//  QRiosity
//
//  Created by Claude on 2024/12/14.
//

import SwiftUI

struct BarcodeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let barCount = 6
        let spacing = rect.width * 0.08
        let barWidths: [CGFloat] = [1, 0.5, 0.5, 1, 0.5, 1]
        let totalWidthRatio = barWidths.reduce(0, +)
        let totalSpacing = spacing * CGFloat(barCount - 1)
        let availableWidth = rect.width - totalSpacing

        var currentX = rect.minX

        for widthRatio in barWidths {
            let barWidth = (availableWidth * widthRatio) / totalWidthRatio
            let barHeight = rect.height
            let y = rect.minY

            let barRect = CGRect(x: currentX, y: y, width: barWidth, height: barHeight)
            let barPath = RoundedRectangle(cornerRadius: barWidth / 2).path(in: barRect)
            path.addPath(barPath)

            currentX += barWidth + spacing
        }

        return path
    }
}

struct CapsuleGroupShape_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            Color.clear
                .glassEffect(.clear, in: BarcodeShape())
                .frame(width: 200, height: 180)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding()
        .background(LinearGradient(colors: [Color.blue, Color.white], startPoint: .bottom, endPoint: .top).ignoresSafeArea())
    }
}
