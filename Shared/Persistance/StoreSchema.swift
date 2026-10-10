import Foundation
import SwiftData

// MARK: - StoreSchemaV1

/// The frozen schema matching the original, unversioned SwiftData store.
///
/// Preserve these persisted properties when adding subsequent schema versions.
nonisolated enum StoreSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [CodeRecord.self] }

    // MARK: - CodeRecord

    @Model
    final class CodeRecord {
        /// The original persisted description field, retained to reproduce the legacy schema.
        var desc: String?
        var isDeletedFromHistory: Bool = false
        var isFavorite: Bool = false
        var metadataObjectType: String
        var previewImageURLString: String?
        var scannedAt: Date
        var stringValue: String
        var title: String?

        init(stringValue: String, metadataObjectType: String, scannedAt: Date = Date()) {
            self.stringValue = stringValue
            self.metadataObjectType = metadataObjectType
            self.scannedAt = scannedAt
            self.isFavorite = false
            self.isDeletedFromHistory = false
        }
    }
}

// MARK: - StoreSchemaV2

/// The schema that adds labels and data migration metadata.
nonisolated enum StoreSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [CodeRecord.self, CodeLabel.self, StoreMetadata.self]
    }
}

// MARK: - StoreMigrationPlan

/// The supported sequence of structural store upgrades.
nonisolated enum StoreMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [StoreSchemaV1.self, StoreSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: StoreSchemaV1.self, toVersion: StoreSchemaV2.self)]
    }
}

// MARK: - LabelMigration

/// The migration of collected records to the unnamed Bookmark label.
@MainActor
enum LabelMigration {
    /// The data migration version recorded in ``StoreMetadata`` once this migration completes.
    static let currentVersion = 3

    /// Migrates legacy collections to Bookmark and records completion in the same transaction.
    ///
    /// Imports legacy favorite flags only for stores predating labels. The current
    /// version resets the existing Bookmark label to an unnamed bookmark, preserving its
    /// identity, record relationships, and all custom labels.
    ///
    /// Repeated calls leave completed migrations unchanged. A failed transaction
    /// rolls back both relationships and metadata so a later call can retry.
    ///
    /// - Parameters:
    ///   - context: A dedicated context with autosaving disabled.
    ///   - beforeSave: An operation performed before committing, used to test failure recovery.
    /// - Throws: A fetch, save, or `beforeSave` error.
    /// - Precondition: The caller holds exclusive store initialization access.
    static func run(in context: ModelContext, beforeSave: () throws -> Void = {}) throws {
        let metadata = try context.fetch(FetchDescriptor<StoreMetadata>()).first
        let previousVersion = metadata?.dataMigrationVersion ?? 0
        guard previousVersion < currentVersion else { return }
        do {
            try context.transaction {
                let labels = try context.fetch(FetchDescriptor<CodeLabel>())
                let bookmark: CodeLabel
                if let existing = labels.first(where: { $0.id == CodeLabel.bookmarkID }) {
                    bookmark = existing
                } else {
                    bookmark = CodeLabel(id: CodeLabel.bookmarkID, symbolName: "bookmark.fill")
                    context.insert(bookmark)
                }
                bookmark.symbolName = "bookmark.fill"
                bookmark.title = nil
                // Sorts Bookmark before custom labels regardless of the device clock.
                bookmark.creationDate = Date(timeIntervalSince1970: 0)
                if previousVersion < 1 {
                    let records = try context.fetch(FetchDescriptor<CodeRecord>(
                        predicate: #Predicate { $0.isFavorite }
                    ))
                    for record in records where !record.labels.contains(where: { $0.id == bookmark.id }) {
                        record.labels.append(bookmark)
                    }
                }
                let state = metadata ?? StoreMetadata()
                if metadata == nil { context.insert(state) }
                state.dataMigrationVersion = currentVersion
                try beforeSave()
                try context.save()
            }
        } catch {
            context.rollback()
            throw error
        }
    }
}
