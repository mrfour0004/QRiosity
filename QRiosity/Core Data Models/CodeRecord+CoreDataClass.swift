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

}

// MARK: - Class function

extension CodeRecord {
//    class func instantiate(with stringValue: String) -> CodeRecord? {
//        let barcodeString = stringValue
//
//        let request: NSFetchRequest<CodeRecord> = CodeRecord.fetchRequest()
//        let predicate = NSPredicate(format: "stringValue = %@", barcodeString)
//        request.predicate = predicate
//
//        return instantiate(with: request)
//    }

    class func instantiate(with codeObject: AVMetadataMachineReadableCodeObject, in context: NSManagedObjectContext) -> CodeRecord {
        instantiate(withString: codeObject.stringValue!, type: codeObject.type, in: context)
    }

    class func instantiate(withString value: String, type: AVMetadataObject.ObjectType, in context: NSManagedObjectContext) -> CodeRecord {
        //loggingPrint("Creating an instance of CodeRecord for barcode content: \(value), and barcode type: \(type.rawValue)")

        let instance = CodeRecord(context: context)
        instance.isFavorite = false
        instance.scannedAt = Date()
        instance.stringValue = value
        instance.metadataObjectType = type.rawValue

        return instance
    }
}
