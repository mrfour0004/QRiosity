//
//  Persistence.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import AVFoundation
import SwiftData

/// A migrated SwiftData container shared by the app and widget.
@MainActor
struct PersistenceController {
    private static var cached: PersistenceController?

    /// The process's shared controller, retrying initialization after failures.
    ///
    /// - Throws: A store initialization or migration error.
    static var shared: PersistenceController {
        get throws {
            if let cached { return cached }
            let controller = try PersistenceController()
            cached = controller
            return controller
        }
    }

    static let preview: PersistenceController = {
        let result = try! PersistenceController(storage: .inMemory)
        let modelContext = result.modelContext

        for index in 0 ..< 10 {
            let instance = CodeRecord(
                stringValue: index == 0 ? "https://www.github.com/mrfour0004" : UUID().uuidString,
                metadataObjectType: index == 0 ? AVMetadataObject.ObjectType.qr.rawValue : AVMetadataObject.ObjectType.code39.rawValue,
                scannedAt: Date()
            )
            instance.labels = (try? modelContext.fetch(FetchDescriptor<CodeLabel>())) ?? []

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

    /// Where a controller keeps its data.
    enum Storage {
        /// The persistent store in the App Group container shared by the app and widget.
        case appGroup
        /// Temporary, memory-only storage.
        case inMemory
        /// A persistent store at the specified file location.
        case file(URL)
    }

    /// Creates a container and completes schema and label migrations before returning.
    ///
    /// - Parameter storage: Where to keep the data.
    /// - Throws: A locking, container initialization, or data migration error.
    init(storage: Storage = .appGroup) throws {
        let schema = Schema(versionedSchema: StoreSchemaV2.self)
        var storeLock: StoreLock?
        let modelConfiguration: ModelConfiguration

        switch storage {
        case .inMemory:
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        case .appGroup, .file:
            let storeURL: URL
            if case .file(let url) = storage {
                storeURL = url
            } else {
                let baseURL = FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.mrfour.test")
                    ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                storeURL = baseURL.appendingPathComponent("CodeReader.sqlite")
            }
            try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            storeLock = try StoreLock(url: storeURL.appendingPathExtension("migration.lock"))

            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
        }

        defer { withExtendedLifetime(storeLock) {} }
        modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: StoreMigrationPlan.self,
            configurations: [modelConfiguration]
        )
        let migrationContext = ModelContext(modelContainer)
        migrationContext.autosaveEnabled = false
        try LabelMigration.run(in: migrationContext)
    }
}
