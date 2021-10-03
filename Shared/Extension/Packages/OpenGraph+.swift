//
//  OpenGraph+.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/2.
//  Copyright © 2021 mrfour. All rights reserved.
//

import Foundation
import OpenGraph

extension OpenGraph {
    static func fetch(_ url: URL) async throws -> OpenGraph {
        try await withCheckedThrowingContinuation { continuation in
            fetch(url: url) { result in
                switch result {
                case .success(let openGraph):
                    continuation.resume(returning: openGraph)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
