//
//  PDF417Generator.swift
//  QRiosity
//
//  Created by Claude on 2025-09-07.
//  Copyright © 2021 mrfour. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import UIKit

struct PDF417Generator: BarcodeGenerator {
    func generateImage(from content: String) -> UIImage? {
        guard let data = content.data(using: .utf8) else {
            return nil
        }
        
        let generator = CIFilter.pdf417BarcodeGenerator()
        generator.message = data
        generator.minWidth = 200.0
        generator.maxWidth = 400.0
        generator.minHeight = 100.0
        generator.maxHeight = 200.0
        generator.compactionMode = 0
        
        let colorInvertFilter = CIFilter.colorInvert()
        let maskToAlphaFilter = CIFilter.maskToAlpha()
        
        colorInvertFilter.inputImage = generator.outputImage
        maskToAlphaFilter.inputImage = colorInvertFilter.outputImage
        colorInvertFilter.inputImage = maskToAlphaFilter.outputImage
        
        guard let ciImage = colorInvertFilter.outputImage else {
            return nil
        }
        
        let targetSize = CGSize(width: 300, height: 150)
        let scaleX = targetSize.width / ciImage.extent.width
        let scaleY = targetSize.height / ciImage.extent.height
        let scale = min(scaleX, scaleY)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}