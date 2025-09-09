//
//  BarcodeGeneratorFactory.swift
//  QRiosity
//
//  Created by Claude on 2025-09-07.
//  Copyright © 2021 mrfour. All rights reserved.
//

import Foundation

struct BarcodeGeneratorFactory {
    static func makeGenerator(type: String) -> BarcodeGenerator? {
        switch type {
        case "org.iso.QRCode":
            return QRCodeGenerator()
        case "org.iso.Code128":
            return Code128Generator()
        case "org.iso.PDF417":
            return PDF417Generator()
        case "org.iso.Aztec":
            return AztecCodeGenerator()
        default:
            return nil
        }
    }
}
