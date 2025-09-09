//
//  QRCodeGenerator.swift
//  QRiosity
//
//  Created by Claude on 2025-09-07.
//  Copyright © 2021 mrfour. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeGenerator: BarcodeGenerator {
    func generateImage(from content: String) -> UIImage? {
        guard let data = content.data(using: .utf8) else {
            return nil
        }

        let generator = CIFilter.roundedQRCodeGenerator()
        generator.message = data
        generator.correctionLevel = "H"

        let colorInvertFilter = CIFilter.colorInvert()
        let maskToAlphaFilter = CIFilter.maskToAlpha()

        colorInvertFilter.inputImage = generator.outputImage
        maskToAlphaFilter.inputImage = colorInvertFilter.outputImage
        colorInvertFilter.inputImage = maskToAlphaFilter.outputImage

        guard let ciImage = colorInvertFilter.outputImage else {
            return nil
        }

        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
