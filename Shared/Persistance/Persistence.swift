//
//  Persistence.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import AVFoundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let instance = CodeRecord(context: viewContext)
            instance.stringValue = UUID().uuidString
            instance.scannedAt = Date()
            instance.isFavorite = false
            instance.metadataObjectType = AVMetadataObject.ObjectType.code39.rawValue
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CodeReader")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores { _, _ in fatalError("Can't load memory persistent storage") }
            return
        }

        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.mrfour.8codereader")!
            .appendingPathComponent("CodeReader.sqlite")

        let defaultURL = container.persistentStoreDescriptions.first
            .flatMap(\.url)
            .flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }

        if defaultURL == nil {
            // nil default url means data is migrated or this is user's first try.
            // so we can use the shared store safely.
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        }

        container.loadPersistentStores(completionHandler: { [container] (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            // Migrate default store (if any) to shared store.
            guard let defaultURL = defaultURL, defaultURL.absoluteString != storeURL.absoluteString else { return }
            let coordinator = container.persistentStoreCoordinator

            guard let oldStore = coordinator.persistentStore(for: defaultURL) else { return }
            do {
                try coordinator.migratePersistentStore(oldStore, to: storeURL, options: nil, withType: NSSQLiteStoreType)
            } catch {
                print(error.localizedDescription)
            }

            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            fileCoordinator.coordinate(writingItemAt: defaultURL, options: .forDeleting, error: nil, byAccessor: { url in
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error.localizedDescription)
                }
            })
        })
    }
}
