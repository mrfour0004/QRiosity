//
//  BarcodeGenerator.swift
//  QRiosity
//
//  Created by Claude on 2025-09-07.
//  Copyright © 2021 mrfour. All rights reserved.
//

import UIKit

protocol BarcodeGenerator {
    func generateImage(from content: String) -> UIImage?
}