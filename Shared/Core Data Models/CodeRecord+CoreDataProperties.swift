//
//  CodeRecord+CoreDataProperties.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//
//

import Foundation
import CoreData


extension CodeRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CodeRecord> {
        return NSFetchRequest<CodeRecord>(entityName: "CodeRecord")
    }

    @NSManaged public var desc: String?
    @NSManaged public var isDeletedFromHistory: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var metadataObjectType: String
    @NSManaged public var previewImageURLString: String?
    @NSManaged public var scannedAt: Date
    @NSManaged public var stringValue: String
    @NSManaged public var title: String?

}

extension CodeRecord : Identifiable {

}
