//
//  CodeRecord+CoreDataClass.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//
//

import AVFoundation
import CoreData
import Foundation
import OpenGraph

@objc(CodeRecord)
public class CodeRecord: NSManagedObject {
    enum RecordType {
        case url
        case string
    }

    var type: RecordType {
        url.flatMap { _ in RecordType.url } ?? .string
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

// MARK: - Getting Link Metadata

extension CodeRecord {
    /// Fetches the metadata for the link if barcode content is a URL.
    func fetchLinkMetadataIfNeeded(context: NSManagedObjectContext) {
        guard let url = URL(string: stringValue) else { return }

        Task {
            guard let openGraph = try? await OpenGraph.fetch(url) else { return }
            updateMetadata(with: openGraph)

            if context.hasChanges {
                try? context.save()
            }
        }
    }

    private func updateMetadata(with openGraph: OpenGraph) {
        title = openGraph[.title]?.trimmed ?? stringValue

        if title != stringValue {
            desc = stringValue
        }

        desc = openGraph[.description]?.trimmed ?? desc
        previewImageURLString = openGraph[.image]?.trimmed
    }
}


// MARK: - Class function

extension CodeRecord {
    class func instantiate(
        with codeObject: AVMetadataMachineReadableCodeObject,
        in context: NSManagedObjectContext
    ) -> CodeRecord {
        instantiate(withString: codeObject.stringValue!, type: codeObject.type, in: context)
    }

    class func instantiate(
        withString value: String,
        type: AVMetadataObject.ObjectType,
        in context: NSManagedObjectContext
    ) -> CodeRecord {
        //loggingPrint("Creating an instance of CodeRecord for barcode content: \(value), and barcode type: \(type.rawValue)")

        let instance = CodeRecord(context: context)
        instance.isFavorite = false
        instance.scannedAt = Date()
        instance.stringValue = value
        instance.metadataObjectType = type.rawValue

        return instance
    }
}
