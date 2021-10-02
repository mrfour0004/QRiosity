//
//  NSManagedObject.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/2.
//  Copyright © 2021 mrfour. All rights reserved.
//

import CoreData

extension NSManagedObject {
    class func instances<Object: NSManagedObject>(with request: NSFetchRequest<Object>) -> [Object]? {
        try? PersistenceController.shared.container.viewContext.fetch(request)
    }

    class func instance<Object: NSManagedObject>(with request: NSFetchRequest<Object>) -> Object? {
        instances(with: request)?.first
    }
}
