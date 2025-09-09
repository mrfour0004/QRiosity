//
//  AztecCodeGenerator.swift
//  QRiosity
//
//  Created by Claude on 2025-09-07.
//  Copyright © 2021 mrfour. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import UIKit

struct AztecCodeGenerator: BarcodeGenerator {
    func generateImage(from content: String) -> UIImage? {
        guard let data = content.data(using: .utf8) else {
            return nil
        }
        
        let generator = CIFilter.aztecCodeGenerator()
        generator.message = data
        generator.correctionLevel = 23
        
        let colorInvertFilter = CIFilter.colorInvert()
        let maskToAlphaFilter = CIFilter.maskToAlpha()
        
        colorInvertFilter.inputImage = generator.outputImage
        maskToAlphaFilter.inputImage = colorInvertFilter.outputImage
        colorInvertFilter.inputImage = maskToAlphaFilter.outputImage
        
        guard let ciImage = colorInvertFilter.outputImage else {
            return nil
        }
        
        let targetSize = CGSize(width: 200, height: 200)
        let scaleX = targetSize.width / ciImage.extent.width
        let scaleY = targetSize.height / ciImage.extent.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}