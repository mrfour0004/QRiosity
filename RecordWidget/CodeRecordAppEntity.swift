//
//  CodeRecordAppEntity.swift
//  RecordWidget
//
//  Created by AL02413554 on 2025/10/26.
//  Copyright © 2025 mrfour. All rights reserved.
//

import AppIntents
import Foundation
import SwiftData

struct CodeRecordEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Collected Barcode"
    static var defaultQuery = CodeRecordEntityQuery()

    var id: String
    var title: String
    var stringValue: String
    var metadataObjectType: String
    var scannedAt: Date

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(stringValue)"
        )
    }

    init(id: String, title: String, stringValue: String, metadataObjectType: String, scannedAt: Date) {
        self.id = id
        self.title = title
        self.stringValue = stringValue
        self.metadataObjectType = metadataObjectType
        self.scannedAt = scannedAt
    }

    init(from record: CodeRecord) {
        self.id = record.persistentModelID.hashValue.description
        self.title = record.title ?? record.stringValue
        self.stringValue = record.stringValue
        self.metadataObjectType = record.metadataObjectType
        self.scannedAt = record.scannedAt
    }
}

struct CodeRecordEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [CodeRecordEntity] {
        let records = try collectedRecords()
        return records.map(CodeRecordEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [CodeRecordEntity] {
        let records = try collectedRecords()
        return records.map(CodeRecordEntity.init)
    }

    @MainActor
    func defaultResult() async throws -> CodeRecordEntity? {
        let record = try collectedRecords(fetchLimit: 1).first
        return record.map(CodeRecordEntity.init)
    }

    @MainActor
    private func collectedRecords(fetchLimit: Int = 20) throws -> [CodeRecord] {
        let persistenceController = PersistenceController.shared
        let modelContext = persistenceController.modelContext

        var descriptor = FetchDescriptor<CodeRecord>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\CodeRecord.scannedAt, order: .reverse)]
        )
        descriptor.fetchLimit = fetchLimit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching default record: \(error)")
            return []
        }
    }
}
