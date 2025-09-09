//
//  Code128Generator.swift
//  QRiosity
//
//  Created by Claude on 2025-09-07.
//  Copyright © 2021 mrfour. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import UIKit

struct Code128Generator: BarcodeGenerator {
    func generateImage(from content: String) -> UIImage? {
        guard let data = content.data(using: .ascii) else {
            return nil
        }
        
        let generator = CIFilter.code128BarcodeGenerator()
        generator.message = data
        generator.quietSpace = 10.0
        generator.barcodeHeight = 80.0
        
        let colorInvertFilter = CIFilter.colorInvert()
        let maskToAlphaFilter = CIFilter.maskToAlpha()
        
        colorInvertFilter.inputImage = generator.outputImage
        maskToAlphaFilter.inputImage = colorInvertFilter.outputImage
        colorInvertFilter.inputImage = maskToAlphaFilter.outputImage
        
        guard let ciImage = colorInvertFilter.outputImage else {
            return nil
        }
        
        let targetWidth: CGFloat = 300
        let scaleX = targetWidth / ciImage.extent.width
        let scaleY: CGFloat = 1.0
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}