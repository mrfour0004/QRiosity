//
//  VisualEffect.swift
//  QRiosity
//
//  Created by mrfour on 2022/1/7.
//  Copyright © 2022 mrfour. All rights reserved.
//

import SwiftUI

struct VisualEffect: UIViewRepresentable {

    private let effect: UIVisualEffect

    init(effect: UIVisualEffect) {
        self.effect = effect
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }

}
