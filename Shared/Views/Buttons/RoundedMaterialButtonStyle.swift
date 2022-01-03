//
//  RoundedMaterialButtonStyle.swift
//  QRiosity
//
//  Created by mrfour on 2021/12/26.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftUI

/// A button style that applies a large corner radius and material background based on the button's context.
///
/// - Note: This is currently the main style for buttons whose `label` is an icon. May have a more mature design system
/// and have a better name in the next phase.
struct RoundedMaterialButtonStyle: ButtonStyle {
    enum Design {
        static let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 24, height: 24)
            // TODO: will have a better color for destructive later
            .foregroundColor(configuration.role == .destructive ? .red : .secondary)
            .padding()
            .background(.ultraThickMaterial, in: Design.shape)
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .background(.ultraThinMaterial, in: Design.shape)
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.spring(response: 0.4), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RoundedMaterialButtonStyle {
    /// A button style that applies a large corner radius and material background based on the button's context.
    ///
    /// To apply this style to a button, or to a view that contains buttons, use the `buttonStyle(_:)` modifier.
    static var roundedMaterial: RoundedMaterialButtonStyle {
        RoundedMaterialButtonStyle()
    }
}
