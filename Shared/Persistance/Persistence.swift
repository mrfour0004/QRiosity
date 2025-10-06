//
//  Persistence.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import AVFoundation
import SwiftData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let modelContext = result.modelContext

        for index in 0 ..< 10 {
            let instance = CodeRecord(
                stringValue: index == 0 ? "https://www.github.com/mrfour0004" : UUID().uuidString,
                metadataObjectType: index == 0 ? AVMetadataObject.ObjectType.qr.rawValue : AVMetadataObject.ObjectType.code39.rawValue,
                scannedAt: Date()
            )
            instance.isFavorite = true

            if index == 0 {
                instance.title = "mrfour0004 on GitHub"
                instance.previewImageURLString = "https://source.unsplash.com/user/c_v_r/100x100"
            }

            modelContext.insert(instance)
        }

        do {
            try modelContext.save()
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return result
    }()

    let modelContainer: ModelContainer
    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    init(inMemory: Bool = false) {
        let schema = Schema([CodeRecord.self])
        let modelConfiguration: ModelConfiguration

        if inMemory {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            let storeURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.com.mrfour.test")!
                .appendingPathComponent("CodeReader.sqlite")

            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
