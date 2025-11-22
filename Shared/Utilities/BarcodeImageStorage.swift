//
//  BarcodeImageStorage.swift
//  QRiosity
//
//  Created by Claude on 2025-11-22.
//  Copyright © 2025 mrfour. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

final class BarcodeImageStorage {
    // MARK: - Shared Instance

    static let shared = BarcodeImageStorage()

    // MARK: - Properties

    private let fileManager: FileManager
    private let appGroupIdentifier = "group.com.mrfour.test"

    // MARK: - Creating image storage

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    @discardableResult
    func saveImage(_ image: UIImage, barcodeType: String, stringValue: String) -> Bool {
        guard let directory = barcodeImagesDirectory, let data = image.pngData() else {
            return false
        }

        let filename = makeFilename(barcodeType: barcodeType, stringValue: stringValue)
        let fileURL = directory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving barcode image: \(error)")
            return false
        }
    }

    func loadImage(barcodeType: String, stringValue: String) -> UIImage? {
        guard let directory = barcodeImagesDirectory else { return nil }
        let filename = makeFilename(barcodeType: barcodeType, stringValue: stringValue)
        let fileURL = directory.appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return UIImage(data: data)
    }

    func deleteImage(barcodeType: String, stringValue: String) {
        guard let directory = barcodeImagesDirectory else { return }
        let filename = makeFilename(barcodeType: barcodeType, stringValue: stringValue)
        let fileURL = directory.appendingPathComponent(filename)

        try? fileManager.removeItem(at: fileURL)
    }

    private func makeFilename(barcodeType: String, stringValue: String) -> String {
        let combined = "\(barcodeType)_\(stringValue)"
        let hash = combined.sha256()
        return "\(hash).png"
    }

    // MARK: - Managing Directories

    private lazy var containerURL = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupIdentifier
    )

    private lazy var barcodeImagesDirectory: URL? = {
        guard let containerURL else { return nil }
        let directory = containerURL.appendingPathComponent("BarcodeImages", isDirectory: true)

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory
    }()
}

private struct BarcodeImageStorageKey: EnvironmentKey {
    static let defaultValue: BarcodeImageStorage = .shared
}

extension EnvironmentValues {
    var barcodeImageStorage: BarcodeImageStorage {
        get { self[BarcodeImageStorageKey.self] }
        set { self[BarcodeImageStorageKey.self] = newValue }
    }
}
