//
//  CodeRecord+CoreDataClass.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//
//

import Foundation
import CoreData
import AVFoundation

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
