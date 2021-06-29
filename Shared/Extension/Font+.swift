//
//  Font+.swift
//  QRiosity
//
//  Created by mrfour on 2021/6/13.
//

import SwiftUI

extension Font {
    static func avenir(_ style: TextStyle) -> Font {
        func makeAvenir(size: CGFloat, weight: Weight = .regular) -> Font {
            makeFont(name: "Avenir", size: size, weight: weight, textStyle: style)
        }

        switch style {
        case .largeTitle:
            return makeAvenir(size: 32)
        case .title:
            return makeAvenir(size: 28)
        case .title2:
            return makeAvenir(size: 22)
        case .title3:
            return makeAvenir(size: 20)
        case .headline:
            return makeAvenir(size: 17, weight: .bold)
        case .subheadline:
            return makeAvenir(size: 15)
        case .body:
            return makeAvenir(size: 17)
        case .callout:
            return makeAvenir(size: 16)
        case .footnote:
            return makeAvenir(size: 13)
        case .caption:
            return makeAvenir(size: 12)
        case .caption2:
            return makeAvenir(size: 10)
        @unknown default:
            return makeAvenir(size: 17)
        }
    }

    private static func makeFont(name: String, size: CGFloat, weight: Weight, textStyle: TextStyle) -> Font {
        Font.custom(name, size: size, relativeTo: textStyle).weight(weight)
    }
}
