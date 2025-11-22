//
//  RecordWidget.swift
//  RecordWidget
//
//  Created by AL02413554 on 2025/10/10.
//  Copyright © 2025 mrfour. All rights reserved.
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct RecordWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = RecordWidgetEntry
    typealias Intent = SelectRecordIntent

    let imageStorage: BarcodeImageStorage

    init(imageStorage: BarcodeImageStorage = .shared) {
        self.imageStorage = imageStorage
    }

    func placeholder(in context: Context) -> RecordWidgetEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectRecordIntent, in context: Context) async -> RecordWidgetEntry {
        let entity: CodeRecordEntity? = if let recordEntity = configuration.record {
            recordEntity
        } else {
            try? await CodeRecordEntity.defaultQuery.defaultResult()
        }

        guard let entity else { return .placeholder }

        return RecordWidgetEntry(
            date: Date(),
            recordEntity: entity,
            image: image(for: entity)
        )
    }

    func timeline(for configuration: SelectRecordIntent, in context: Context) async -> Timeline<RecordWidgetEntry> {
        let entity: CodeRecordEntity? = if let recordEntity = configuration.record {
            recordEntity
        } else {
            try? await CodeRecordEntity.defaultQuery.defaultResult()
        }

        let entry = entity.flatMap {
            RecordWidgetEntry(date: Date(), recordEntity: $0, image: image(for: $0))
        } ?? .placeholder

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: - Loading image for barcode

    private func image(for entity: CodeRecordEntity) -> UIImage? {
        imageStorage.loadImage(
            barcodeType: entity.metadataObjectType,
            stringValue: entity.stringValue
        )
    }
}

// MARK: - Widget Entry

struct RecordWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let stringValue: String
    private(set) var image: UIImage?

    init(date: Date, recordEntity: CodeRecordEntity, image: UIImage? = nil) {
        self.date = date
        self.title = recordEntity.title
        self.stringValue = recordEntity.stringValue
        self.image = image
    }

    init(date: Date, title: String, stringValue: String, image: UIImage? = nil) {
        self.date = date
        self.title = title
        self.stringValue = stringValue
        self.image = image
    }
}

extension RecordWidgetEntry {
    static let placeholder = RecordWidgetEntry(
        date: Date(),
        title: "No favorite records",
        stringValue: ""
    )
}

// MARK: - Widget Views

struct RecordWidgetEntryView: View {
    var entry: RecordWidgetEntry

    var body: some View {
        if let image = entry.image {
            VStack(spacing: 8) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()

                Text(entry.title)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal)
            }
        } else {
            Text(entry.title)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

// MARK: - Widget Configuration

struct RecordWidget: Widget {
    let kind: String = "RecordWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRecordIntent.self, provider: RecordWidgetProvider()) { entry in
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
        title: "Sample Title",
        stringValue: "https://example.com",
        image: QRCodeGenerator().generateImage(from: "https://example.com")
    )
}
