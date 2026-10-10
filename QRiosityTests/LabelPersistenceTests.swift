import SwiftData
import Foundation
import Testing
@testable import QRiosity

// MARK: - LabelPersistenceTests

@Suite("Label persistence and migration")
@MainActor
struct LabelPersistenceTests {
    private func toggleBookmark(_ record: CodeRecord, in context: ModelContext) throws {
        let bookmark = try #require(context.fetch(FetchDescriptor<CodeLabel>()).first { $0.isBookmark })
        let selection = record.isBookmarked ? record.labels.filter { !$0.isBookmark } : record.labels + [bookmark]
        try LabelStore.setLabels(selection, for: record, in: context)
    }

    private func emptyContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: StoreSchemaV2.self)
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        ])
    }

    @Test func `Migration preserves records and History visibility`() throws {
        let container = try emptyContainer()
        let context = container.mainContext
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let favorite = CodeRecord(stringValue: "https://example.com", metadataObjectType: "org.iso.QRCode", scannedAt: date)
        favorite.isFavorite = true
        favorite.isDeletedFromHistory = true
        favorite.title = "Original title"
        favorite.recordDescription = "Original description"
        favorite.previewImageURLString = "https://example.com/preview.png"
        let ordinary = CodeRecord(stringValue: "12345", metadataObjectType: "code39")
        context.insert(favorite)
        context.insert(ordinary)
        try context.save()

        try LabelMigration.run(in: context)
        try LabelMigration.run(in: context)

        #expect(favorite.isBookmarked)
        #expect(favorite.isDeletedFromHistory)
        #expect(favorite.labels.count == 1)
        #expect(favorite.scannedAt == date)
        #expect(favorite.title == "Original title")
        #expect(favorite.recordDescription == "Original description")
        #expect(favorite.previewImageURLString == "https://example.com/preview.png")
        #expect(!(ordinary.hasLabels))
        #expect(try context.fetchCount(FetchDescriptor<CodeLabel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CodeRecord>()) == 2)
    }

    @Test func `Empty migration creates one Bookmark label`() throws {
        let container = try emptyContainer()
        try LabelMigration.run(in: container.mainContext)
        try LabelMigration.run(in: container.mainContext)
        let labels = try container.mainContext.fetch(FetchDescriptor<CodeLabel>())
        #expect(labels.count == 1)
        #expect(labels.first?.id == CodeLabel.bookmarkID)
        #expect(labels.first?.isBookmark == true)
        #expect(labels.first?.records.isEmpty == true)
    }

    @Test func `Bookmark sorts before custom labels by creation date`() throws {
        let container = try emptyContainer()
        let context = container.mainContext
        try LabelMigration.run(in: context)
        let custom = try LabelStore.save(title: "Work", symbolName: "briefcase.fill", in: context)
        custom.creationDate = Date(timeIntervalSince1970: 1)
        try context.save()
        let sorted = try context.fetch(FetchDescriptor<CodeLabel>(sortBy: [SortDescriptor(\.creationDate)]))
        #expect(sorted.map(\.id) == [CodeLabel.bookmarkID, custom.id])
    }

        // MARK: - InjectedFailure

    @Test func `Migration failure rolls back and can be retried`() throws {
        enum InjectedFailure: Error { case beforeSave }
        let container = try emptyContainer()
        let context = container.mainContext
        context.autosaveEnabled = false
        let record = CodeRecord(stringValue: "saved", metadataObjectType: "QR")
        record.isFavorite = true
        context.insert(record)
        try context.save()
        #expect(throws: InjectedFailure.self) { try LabelMigration.run(in: context) { throw InjectedFailure.beforeSave } }
        let reader = ModelContext(container)
        #expect(try reader.fetchCount(FetchDescriptor<StoreMetadata>()) == 0)
        #expect(try reader.fetchCount(FetchDescriptor<CodeLabel>()) == 0)
        #expect(try reader.fetchCount(FetchDescriptor<CodeRecord>()) == 1)
        try LabelMigration.run(in: context)
        #expect(try #require(context.fetch(FetchDescriptor<CodeRecord>()).first).isBookmarked)
    }

    @Test func `Removing Bookmark is not undone by migration`() throws {
        let container = try emptyContainer()
        let context = container.mainContext
        let record = CodeRecord(stringValue: "saved", metadataObjectType: "QR")
        record.isFavorite = true
        record.isDeletedFromHistory = true
        context.insert(record)
        try context.save()
        try LabelMigration.run(in: context)
        try toggleBookmark(record, in: context)
        try LabelMigration.run(in: context)
        #expect(record.isFavorite, "Legacy data stays untouched, proving the marker prevents re-import.")
        #expect(!(record.isBookmarked))
        #expect(!(record.isDeletedFromHistory))
    }

    @Test func `Bookmark label cannot be changed or deleted`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let favorites = try #require(context.fetch(FetchDescriptor<CodeLabel>()).first)
        #expect(throws: LabelStore.ValidationError.bookmarkLabel) { try LabelStore.delete(favorites, in: context) }
        #expect(throws: LabelStore.ValidationError.bookmarkLabel) { try LabelStore.save(favorites, title: "Renamed", symbolName: "tag.fill", in: context) }
        #expect(favorites.symbolName == "bookmark.fill")
    }

    @Test func `Clearing History retains custom labels and Bookmark`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let custom = try LabelStore.save(title: "Work", symbolName: "briefcase.fill", in: context)
        let records = (0..<3).map { CodeRecord(stringValue: "\($0)", metadataObjectType: "QR") }
        records.forEach { context.insert($0) }
        try LabelStore.setLabels([custom], for: records[0], in: context)
        try toggleBookmark(records[1], in: context)
        try LabelStore.clearHistory(records, in: context)
        let remaining = try context.fetch(FetchDescriptor<CodeRecord>())
        #expect(Set(remaining.map(\.stringValue)) == ["0", "1"])
        #expect(remaining.allSatisfy { $0.isDeletedFromHistory })
    }

    @Test func `Deleting a label restores only orphaned codes to History`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let custom = try LabelStore.save(title: "Work", symbolName: "briefcase.fill", in: context)
        let one = CodeRecord(stringValue: "one", metadataObjectType: "QR")
        let two = CodeRecord(stringValue: "two", metadataObjectType: "QR")
        context.insert(one)
        context.insert(two)
        try LabelStore.setLabels([custom], for: one, in: context)
        try LabelStore.setLabels([custom], for: two, in: context)
        try toggleBookmark(two, in: context)
        try LabelStore.clearHistory([one, two], in: context)
        try LabelStore.delete(custom, in: context)
        #expect(!(one.isDeletedFromHistory))
        #expect(!(one.hasLabels))
        #expect(two.isDeletedFromHistory)
        #expect(two.isBookmarked)
        #expect(try context.fetchCount(FetchDescriptor<CodeRecord>()) == 2)
    }

    @Test func `Deleting a code keeps its labels`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let record = CodeRecord(stringValue: "one", metadataObjectType: "QR")
        context.insert(record)
        try toggleBookmark(record, in: context)
        try LabelStore.delete(record, in: context)
        let labels = try context.fetch(FetchDescriptor<CodeLabel>())
        #expect(labels.count == 1)
        #expect(labels[0].records.isEmpty)
    }

    @Test func `Label validation permits distinct titles with the same symbol`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let untitled = try LabelStore.save(title: " \n ", symbolName: "tag.fill", in: context)
        #expect(untitled.title == nil)
        #expect(throws: (any Error).self) { try LabelStore.save(title: "", symbolName: "tag.fill", in: context) }
        _ = try LabelStore.save(title: " Office ", symbolName: "briefcase.fill", in: context)
        _ = try LabelStore.save(title: "Clients", symbolName: "briefcase.fill", in: context)
        #expect(throws: (any Error).self) { try LabelStore.save(title: "office", symbolName: "house.fill", in: context) }
        #expect(throws: (any Error).self) { try LabelStore.save(title: "New", symbolName: "not.a.symbol", in: context) }
    }

    @Test func `Draft labels are only inserted when applied`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let draft = CodeLabel(title: "Draft", symbolName: "tag.fill")
        #expect(try context.fetchCount(FetchDescriptor<CodeLabel>()) == 1)
        let record = CodeRecord(stringValue: "one", metadataObjectType: "QR")
        context.insert(record)
        try LabelStore.setLabels([draft, draft], for: record, in: context)
        #expect(record.labels.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<CodeLabel>()) == 2)
    }

    @Test func `Relationship filters find records for the app and widget`() throws {
        let persistence = try PersistenceController(storage: .inMemory)
        let context = persistence.modelContext
        let record = CodeRecord(stringValue: "one", metadataObjectType: "QR")
        context.insert(record)
        try toggleBookmark(record, in: context)
        let id = CodeLabel.bookmarkID
        #expect(try context.fetchCount(FetchDescriptor<CodeRecord>(predicate: #Predicate { !$0.labels.isEmpty })) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CodeRecord>(predicate: #Predicate { $0.labels.contains { $0.id == id } })) == 1)
    }

    @Test func `Store lock rejects concurrent acquisition and releases`() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        var first: StoreLock? = try StoreLock(url: url)
        _ = withExtendedLifetime(first) { #expect(throws: (any Error).self) { try StoreLock(url: url) } }
        first = nil
        #expect(throws: Never.self) { try StoreLock(url: url) }
    }

    @Test(arguments: [1, 2])
    func `Existing labels migrate to an unnamed bookmark without reimporting removed favorites`(previousVersion: Int) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("CodeReader.sqlite")
        try autoreleasepool {
            let persistence = try PersistenceController(storage: .file(url))
            let context = persistence.modelContext
            let previousSystemLabel = try #require(context.fetch(FetchDescriptor<CodeLabel>()).first)
            previousSystemLabel.symbolName = previousVersion == 1 ? "heart.fill" : "star.fill"
            previousSystemLabel.title = "Previous title"
            let metadata = try #require(context.fetch(FetchDescriptor<StoreMetadata>()).first)
            metadata.dataMigrationVersion = previousVersion
            let removedFavorite = CodeRecord(stringValue: "removed", metadataObjectType: "QR")
            removedFavorite.isFavorite = true
            context.insert(removedFavorite)
            let starred = CodeRecord(stringValue: "starred", metadataObjectType: "QR")
            starred.isDeletedFromHistory = true
            context.insert(starred)
            let unnamedStar = CodeLabel(symbolName: "star.fill")
            let namedStar = CodeLabel(title: "Important", symbolName: "star.fill")
            context.insert(unnamedStar)
            context.insert(namedStar)
            starred.labels = [previousSystemLabel, unnamedStar, namedStar]
            try context.save()
        }
        try autoreleasepool {
            let persistence = try PersistenceController(storage: .file(url))
            let context = persistence.modelContext
            let records = try context.fetch(FetchDescriptor<CodeRecord>())
            let removed = try #require(records.first { $0.stringValue == "removed" })
            let starred = try #require(records.first { $0.stringValue == "starred" })
            let labels = try context.fetch(FetchDescriptor<CodeLabel>())
            let systemBookmark = try #require(labels.first { $0.isBookmark })
            #expect(systemBookmark.id == CodeLabel.bookmarkID)
            #expect(systemBookmark.symbolName == "bookmark.fill")
            #expect(systemBookmark.title == nil)
            #expect(labels.contains { !$0.isBookmark && $0.title == nil && $0.symbolName == "star.fill" })
            #expect(!removed.isBookmarked)
            #expect(starred.isBookmarked)
            #expect(starred.isDeletedFromHistory)
            #expect(starred.labels.count == 3)
            #expect(labels.count == 3)
            #expect(labels.contains { $0.title == "Important" })
            #expect(throws: LabelStore.ValidationError.duplicate) {
                try LabelStore.save(title: "", symbolName: "bookmark.fill", in: context)
            }
        }
    }

    @Test("SQLite upgrades and reopens without restoring removed Bookmark", arguments: [true, false])
    func upgradeSQLite(versioned: Bool) throws {
        try verifyDiskUpgrade(versioned: versioned)
    }

    private func verifyDiskUpgrade(versioned: Bool) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("CodeReader.sqlite")
        try autoreleasepool {
            if versioned {
                let schema = Schema(versionedSchema: StoreSchemaV1.self)
                let old = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
                let record = StoreSchemaV1.CodeRecord(stringValue: "legacy", metadataObjectType: "org.iso.QRCode")
                record.isFavorite = true
                record.isDeletedFromHistory = true
                record.title = "Kept title"
                record.desc = "Kept description"
                old.mainContext.insert(record)
                try old.mainContext.save()
            } else {
                let schema = Schema([LegacyUnversionedSchemaFixture.CodeRecord.self])
                let old = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
                let record = LegacyUnversionedSchemaFixture.CodeRecord(stringValue: "legacy", metadataObjectType: "org.iso.QRCode")
                record.isFavorite = true
                record.isDeletedFromHistory = true
                record.title = "Kept title"
                record.desc = "Kept description"
                old.mainContext.insert(record)
                try old.mainContext.save()
            }
        }
        try autoreleasepool {
            let upgraded = try PersistenceController(storage: .file(url))
            let context = upgraded.modelContext
            let record = try #require(context.fetch(FetchDescriptor<CodeRecord>()).first)
            #expect(record.stringValue == "legacy")
            #expect(record.title == "Kept title")
            #expect(record.recordDescription == "Kept description")
            #expect(record.isBookmarked)
            #expect(record.isDeletedFromHistory)
            #expect(record.labels.count == 1)
            try toggleBookmark(record, in: context)
        }
        try autoreleasepool {
            let reopened = try PersistenceController(storage: .file(url))
            let record = try #require(reopened.modelContext.fetch(FetchDescriptor<CodeRecord>()).first)
            #expect(!(record.isBookmarked))
            #expect(!(record.isDeletedFromHistory))
            #expect(try reopened.modelContext.fetchCount(FetchDescriptor<CodeLabel>()) == 1)
        }
    }
}
