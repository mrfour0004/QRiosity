//
//  CodeRecord.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import AVFoundation
import Foundation
import SwiftData

@Model
final class CodeRecord: Identifiable {
    var desc: String?
    var isDeletedFromHistory: Bool = false
    var isFavorite: Bool = false
    var metadataObjectType: String
    var previewImageURLString: String?
    var scannedAt: Date
    var stringValue: String
    var title: String?

    init(stringValue: String, metadataObjectType: String, scannedAt: Date = Date()) {
        self.stringValue = stringValue
        self.metadataObjectType = metadataObjectType
        self.scannedAt = scannedAt
        self.isFavorite = false
        self.isDeletedFromHistory = false
    }

    enum RecordType {
        case url
        case string
    }

    var type: RecordType {
        url != nil ? .url : .string
    }

    var is2DBarcode: Bool {
        Set(["QRCode", "Aztec", "PDF417"]).contains(metadataObjectType.split(separator: ".").last ?? "")
    }

    /// An URL value that the code content represents for. Returns `nil` if the content is not an URL.
    var url: URL? {
        let availableSchemes = ["https", "http"]
        guard
            let url = URL(string: stringValue),
            let scheme = url.scheme, availableSchemes.contains(scheme.lowercased())
        else { return nil }

        return url
    }
}

// MARK: - Metadata Update

extension CodeRecord {
    func updateMetadata(title: String?, description: String?, previewImageURL: String?) {
        self.title = title
        self.desc = description
        self.previewImageURLString = previewImageURL
    }
}

// MARK: - Class function

extension CodeRecord {
    static func create(
        with codeObject: AVMetadataMachineReadableCodeObject,
        in modelContext: ModelContext
    ) -> CodeRecord {
        create(withString: codeObject.stringValue!, type: codeObject.type, in: modelContext)
    }

    static func create(
        withString value: String,
        type: AVMetadataObject.ObjectType,
        in modelContext: ModelContext
    ) -> CodeRecord {
        let instance = CodeRecord(
            stringValue: value,
            metadataObjectType: type.rawValue,
            scannedAt: Date()
        )

        modelContext.insert(instance)
        return instance
    }
}

// MARK: - Extensions for compatibility
