//
//  ModelContext.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/2.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftData
import Foundation

extension ModelContext {
    func existingCodeRecord(withBarcode barcodeString: String) -> CodeRecord? {
        let predicate = #Predicate<CodeRecord> { $0.stringValue == barcodeString }
        let fetchDescriptor = FetchDescriptor<CodeRecord>(predicate: predicate)
        
        return try? fetch(fetchDescriptor).first
    }
}
