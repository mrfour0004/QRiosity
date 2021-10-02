//
//   NSManagedObjectContext.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/2.
//  Copyright © 2021 mrfour. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func existingCodeRecord(withBarcode barcodeString: String) -> CodeRecord? {
        let request: NSFetchRequest<CodeRecord> = CodeRecord.fetchRequest()
        let predicate = NSPredicate(format: "stringValue = %@", barcodeString)
        request.predicate = predicate

        return try? fetch(request).first
    }
}
