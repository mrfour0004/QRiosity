//
//  CodeRecord.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import AVFoundation
import Foundation
import SwiftData

// MARK: - CodeRecord

@Model
final class CodeRecord: Identifiable {
    /// The descriptive text associated with the code.
    @Attribute(originalName: "desc") var recordDescription: String?
    var isDeletedFromHistory: Bool = false
    /// The legacy favorite value used only when migrating to labels.
    ///
    /// Use ``isBookmarked`` to read the current Bookmark membership.
    var isFavorite: Bool = false
    /// The labels that classify and retain this record.
    @Relationship(deleteRule: .nullify) var labels: [CodeLabel] = []
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

    /// A Boolean value indicating whether this record belongs to Bookmark.
    var isBookmarked: Bool { labels.contains { $0.isBookmark } }
    /// A Boolean value indicating whether labels retain this record outside History.
    var hasLabels: Bool { !labels.isEmpty }

    // MARK: - RecordType

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
    /// Replaces the metadata fetched for the record's URL.
    ///
    /// - Parameters:
    ///   - title: The page title, or `nil` if unavailable.
    ///   - description: The page description, or `nil` if unavailable.
    ///   - previewImageURLString: The preview image address as a string, or `nil` if unavailable.
    func updateMetadata(title: String?, description: String?, previewImageURLString: String?) {
        self.title = title
        self.recordDescription = description
        self.previewImageURLString = previewImageURLString
    }
}

// MARK: - Insertion

extension CodeRecord {
    /// Inserts a new record for a scanned code into the context.
    ///
    /// - Parameters:
    ///   - codeObject: The scanned code, which must have a string value.
    ///   - modelContext: The context into which the record is inserted.
    /// - Returns: The inserted record.
    static func insert(
        _ codeObject: AVMetadataMachineReadableCodeObject,
        in modelContext: ModelContext
    ) -> CodeRecord {
        insert(stringValue: codeObject.stringValue!, type: codeObject.type, in: modelContext)
    }

    /// Inserts a new record with the specified content into the context.
    ///
    /// - Parameters:
    ///   - stringValue: The content of the code.
    ///   - type: The barcode symbology of the code.
    ///   - modelContext: The context into which the record is inserted.
    /// - Returns: The inserted record.
    static func insert(
        stringValue: String,
        type: AVMetadataObject.ObjectType,
        in modelContext: ModelContext
    ) -> CodeRecord {
        let instance = CodeRecord(
            stringValue: stringValue,
            metadataObjectType: type.rawValue,
            scannedAt: Date()
        )

        modelContext.insert(instance)
        return instance
    }
}
