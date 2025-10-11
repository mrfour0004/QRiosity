//
//  RecordWidget.swift
//  RecordWidget
//
//  Created by AL02413554 on 2025/10/10.
//  Copyright © 2025 mrfour. All rights reserved.
//

import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct RecordWidgetProvider: TimelineProvider {
    typealias Entry = RecordWidgetEntry

    private let persistenceController = PersistenceController.shared

    func placeholder(in context: Context) -> RecordWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (RecordWidgetEntry) -> Void) {
        let entry: RecordWidgetEntry
        if let firstFavorite = fetchFirstFavoriteRecord(supportedByFamily: context.family) {
            entry = RecordWidgetEntry(
                date: Date(),
                title: firstFavorite.title ?? firstFavorite.stringValue
            )
        } else {
            entry = .placeholder
        }

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecordWidgetEntry>) -> Void) {
        let entry: RecordWidgetEntry
        if let firstFavorite = fetchFirstFavoriteRecord(supportedByFamily: context.family) {
            entry = RecordWidgetEntry(
                date: Date(),
                title: firstFavorite.title ?? firstFavorite.stringValue
            )
        } else {
            entry = .placeholder
        }

        // Create timeline with single entry that refreshes after 4 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchFirstFavoriteRecord(supportedByFamily family: WidgetFamily) -> CodeRecord? {
        let modelContext = persistenceController.modelContext

        // First try to get a record that matches the preferred type
        var preferredDescriptor = FetchDescriptor<CodeRecord>(
            predicate: #Predicate<CodeRecord> { record in record.isFavorite == true },
            sortBy: [SortDescriptor(\CodeRecord.scannedAt, order: .reverse)]
        )
        preferredDescriptor.fetchLimit = 1

        do {
            let preferredRecords = try modelContext.fetch(preferredDescriptor)
            if let preferredRecord = preferredRecords.first {
                return preferredRecord
            }

            // If no preferred type found, get any favorite record
            var anyDescriptor = FetchDescriptor<CodeRecord>(
                predicate: #Predicate { $0.isFavorite == true },
                sortBy: [SortDescriptor(\CodeRecord.scannedAt, order: .reverse)]
            )
            anyDescriptor.fetchLimit = 1

            let anyRecords = try modelContext.fetch(anyDescriptor)
            return anyRecords.first
        } catch {
            print("Error fetching favorite records: \(error)")
            return nil
        }
    }
}

// MARK: - Widget Entry

struct RecordWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
}

extension RecordWidgetEntry {
    static let placeholder = RecordWidgetEntry(
        date: Date(),
        title: "No favorite records"
    )
}

// MARK: - Widget Views

struct RecordWidgetEntryView: View {
    var entry: RecordWidgetEntry

    var body: some View {
        Text(entry.title)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding()
    }
}

// MARK: - Widget Configuration

struct RecordWidget: Widget {
    let kind: String = "RecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecordWidgetProvider()) { entry in
            RecordWidgetEntryView(entry: entry)
                .widgetAccentable()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Collected Barcode")
        .description("Display the most recent barcode from your collected items.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        [.systemSmall, .systemMedium]
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    RecordWidget()
} timeline: {
    RecordWidgetEntry(
        date: .now,
        title: "Sample Title"
    )
}
