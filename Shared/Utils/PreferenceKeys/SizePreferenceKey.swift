//
//  SizePreferenceKey.swift
//  QRiosity
//
//  Created by AL02413554 on 2025/9/6.
//  Copyright © 2025 mrfour. All rights reserved.
//

import SwiftUI

enum SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func onSizeChange(perform action: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}
