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
        // Content and symbology identify the same barcode across app and widget processes.
        self.id = "\(record.metadataObjectType)_\(record.stringValue)".sha256()
        self.title = record.title ?? record.stringValue
        self.stringValue = record.stringValue
        self.metadataObjectType = record.metadataObjectType
        self.scannedAt = record.scannedAt
    }
}

enum BarcodeFilterType {
    case twoDimensional
    case oneDimensional
}

struct CodeRecordEntityQuery: EntityQuery {
    // The configuration picker has no provider filter; offer all collected barcodes.
    var filterType: BarcodeFilterType?

    @MainActor
    func entities(for identifiers: [String]) async throws -> [CodeRecordEntity] {
        let requestedIDs = Set(identifiers)
        let records = try collectedRecords()
        let entities = records.map(CodeRecordEntity.init)
        var seenIDs = Set<String>()
        return entities.filter {
            requestedIDs.contains($0.id) && seenIDs.insert($0.id).inserted
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [CodeRecordEntity] {
        let records = try collectedRecords()
        var seenIDs = Set<String>()
        return records.map(CodeRecordEntity.init).filter {
            seenIDs.insert($0.id).inserted
        }
    }

    @MainActor
    func defaultResult() async throws -> CodeRecordEntity? {
        let record = try collectedRecords(fetchLimit: 1).first
        return record.map(CodeRecordEntity.init)
    }

    @MainActor
    private func collectedRecords(fetchLimit: Int? = nil) throws -> [CodeRecord] {
        let persistenceController = PersistenceController.shared
        let modelContext = persistenceController.modelContext

        let descriptor = FetchDescriptor<CodeRecord>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\CodeRecord.scannedAt, order: .reverse)]
        )

        let allRecords = try modelContext.fetch(descriptor)
        let filtered = allRecords.filter { record in
            switch filterType {
            case .twoDimensional: record.is2DBarcode
            case .oneDimensional: !record.is2DBarcode
            case nil: true
            }
        }
        if let fetchLimit {
            return Array(filtered.prefix(fetchLimit))
        }
        return filtered
    }
}
