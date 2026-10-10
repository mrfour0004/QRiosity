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
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Labeled Barcode"
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

    /// Creates an entity whose identity is derived from the barcode content and symbology.
    ///
    /// The identifier remains compatible with previously configured widgets.
    init(from record: CodeRecord) {
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
    /// The barcode family to offer, or `nil` to include all labeled codes.
    var filterType: BarcodeFilterType?

    @MainActor
    func entities(for identifiers: [String]) async throws -> [CodeRecordEntity] {
        let requestedIDs = Set(identifiers)
        let entities = try labeledEntities()
        var seenIDs = Set<String>()
        return entities.filter {
            requestedIDs.contains($0.id) && seenIDs.insert($0.id).inserted
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [CodeRecordEntity] {
        let entities = try labeledEntities()
        var seenIDs = Set<String>()
        return entities.filter {
            seenIDs.insert($0.id).inserted
        }
    }

    @MainActor
    func defaultResult() async throws -> CodeRecordEntity? {
        try labeledEntities(fetchLimit: 1).first
    }

    /// Returns current labeled records as entities while their fetch context is alive.
    ///
    /// A fresh context sees changes saved by the app in another process.
    @MainActor
    private func labeledEntities(fetchLimit: Int? = nil) throws -> [CodeRecordEntity] {
        let persistenceController = try PersistenceController.shared
        let modelContext = ModelContext(persistenceController.modelContainer)

        let descriptor = FetchDescriptor<CodeRecord>(
            predicate: #Predicate { !$0.labels.isEmpty },
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
            return filtered.prefix(fetchLimit).map(CodeRecordEntity.init)
        }
        return filtered.map(CodeRecordEntity.init)
    }
}
