//
//  IdentifiableURL.swift
//  QRiosity
//
//  Created by AL02413554 on 2025/9/14.
//  Copyright © 2025 mrfour. All rights reserved.
//

import Foundation

struct IdentifiableURL: Identifiable, Equatable {
    let id: URL

    init(_ url: URL) {
        self.id = url
    }

    func callAsFunction() -> URL { id }
}
