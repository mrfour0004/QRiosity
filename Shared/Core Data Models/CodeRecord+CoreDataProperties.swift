//
//  CodeRecord+CoreDataProperties.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//
//

import CoreData
import Foundation

public nonisolated extension CodeRecord {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CodeRecord> {
        return NSFetchRequest<CodeRecord>(entityName: "CodeRecord")
    }

    @NSManaged var desc: String?
    @NSManaged var isDeletedFromHistory: Bool
    @NSManaged var isFavorite: Bool
    @NSManaged var metadataObjectType: String
    @NSManaged var previewImageURLString: String?
    @NSManaged var scannedAt: Date
    @NSManaged var stringValue: String
    @NSManaged var title: String?
}
