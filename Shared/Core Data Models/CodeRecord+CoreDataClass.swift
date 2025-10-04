//
//  CodeRecord+CoreDataClass.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//
//

import Alamofire
import AVFoundation
import CoreData
import Foundation
import Kanna

private typealias OpenGraph = [String: String]

@objc(CodeRecord)
public nonisolated class CodeRecord: NSManagedObject, Identifiable {
    enum RecordType {
        case url
        case string
    }

    var type: RecordType {
        url.flatMap { _ in RecordType.url } ?? .string
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

// MARK: - Getting Link Metadata

nonisolated extension CodeRecord {
    /// Fetches the metadata for the link if barcode content is a URL.
    func fetchLinkMetadataIfNeeded(context: NSManagedObjectContext) {
        guard let url = URL(string: stringValue) else { return }
        let objectID = self.objectID

        Task {
            do {
                let htmlString = try await AF.request(url).serializingString(encoding: .utf8).value

                try await context.perform {
                    guard let record = try context.existingObject(with: objectID) as? CodeRecord else { return }
                    try record.updateMetadata(with: HTML(html: htmlString, encoding: .utf8))
                    if context.hasChanges {
                        try context.save()
                    }
                }
            } catch {
                print(error.localizedDescription)
                // Handle the error silently as the original code did
            }
        }
    }

    private func updateMetadata(with doc: HTMLDocument) {
        title = doc.title?.trimmed ?? self.stringValue

        if title != stringValue {
            desc = stringValue
        }

        guard let metaSet = doc.head?.css("meta") else {
            return
        }

        var openGraph = OpenGraph()
        for meta in metaSet {
            guard let property = meta["property"]?.lowercased(),
                  property.hasPrefix("og:"),
                  let content = meta["content"]
            else { continue }
            openGraph[property] = content
        }

        title = openGraph["og:title"] ?? title
        desc = openGraph["og:description"] ?? desc
        previewImageURLString = openGraph["og:image"]?.trimmed
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
        // loggingPrint("Creating an instance of CodeRecord for barcode content: \(value), and barcode type: \(type.rawValue)")

        let instance = CodeRecord(context: context)
        instance.isFavorite = false
        instance.scannedAt = Date()
        instance.stringValue = value
        instance.metadataObjectType = type.rawValue

        return instance
    }
}
