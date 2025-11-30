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
    let filterType: BarcodeFilterType

    init(imageStorage: BarcodeImageStorage = .shared, filterType: BarcodeFilterType = .twoDimensional) {
        self.imageStorage = imageStorage
        self.filterType = filterType
    }

    func placeholder(in context: Context) -> RecordWidgetEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectRecordIntent, in context: Context) async -> RecordWidgetEntry {
        var query = CodeRecordEntity.defaultQuery
        query.filterType = filterType

        let entity: CodeRecordEntity? = if let recordEntity = configuration.record {
            recordEntity
        } else {
            try? await query.defaultResult()
        }

        guard let entity else { return .placeholder }

        return RecordWidgetEntry(
            date: Date(),
            recordEntity: entity,
            showTitle: configuration.showTitle,
            image: image(for: entity)
        )
    }

    func timeline(for configuration: SelectRecordIntent, in context: Context) async -> Timeline<RecordWidgetEntry> {
        var query = CodeRecordEntity.defaultQuery
        query.filterType = filterType

        let entity: CodeRecordEntity? = if let recordEntity = configuration.record {
            recordEntity
        } else {
            try? await query.defaultResult()
        }

        let entry = entity.flatMap {
            RecordWidgetEntry(date: Date(), recordEntity: $0, showTitle: configuration.showTitle, image: image(for: $0))
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
    let showTitle: Bool
    private(set) var image: UIImage?

    init(date: Date, recordEntity: CodeRecordEntity, showTitle: Bool = true, image: UIImage? = nil) {
        self.date = date
        self.title = recordEntity.title
        self.stringValue = recordEntity.stringValue
        self.showTitle = showTitle
        self.image = image
    }

    init(date: Date, title: String, stringValue: String, showTitle: Bool = true, image: UIImage? = nil) {
        self.date = date
        self.title = title
        self.stringValue = stringValue
        self.showTitle = showTitle
        self.image = image
    }
}

extension RecordWidgetEntry {
    static let placeholder = RecordWidgetEntry(
        date: Date(),
        title: "No favorite records",
        stringValue: "",
        showTitle: true
    )
}

// MARK: - Widget Views

struct RecordWidgetEntryView: View {
    var entry: RecordWidgetEntry

    var body: some View {
        if let image = entry.image {
            VStack(spacing: 2) {
                if entry.showTitle {
                    Text(entry.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
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

struct RecordWidget2D: Widget {
    let kind: String = "RecordWidget2D"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRecordIntent.self, provider: RecordWidgetProvider(filterType: .twoDimensional)) { entry in
            RecordWidgetEntryView(entry: entry)
                .widgetAccentable()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("2D Barcode")
        .description("Display a 2D barcode (QR, Aztec, PDF417) from your collected items.")
        .supportedFamilies([.systemSmall])
    }
}

struct RecordWidget1D: Widget {
    let kind: String = "RecordWidget1D"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectRecordIntent.self,
            provider: RecordWidgetProvider(filterType: .oneDimensional)
        ) { entry in
            RecordWidgetEntryView(entry: entry)
                .widgetAccentable()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("1D Barcode")
        .description("Display a 1D barcode from your collected items.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Previews

#Preview("2D Barcode", as: .systemSmall) {
    RecordWidget2D()
} timeline: {
    RecordWidgetEntry(
        date: .now,
        title: "Sample QR Code",
        stringValue: "https://example.com",
        image: QRCodeGenerator().generateImage(from: "https://example.com")
    )
}

#Preview("1D Barcode", as: .systemMedium) {
    RecordWidget1D()
} timeline: {
    RecordWidgetEntry(
        date: .now,
        title: "Sample Barcode",
        stringValue: "1234567890",
        image: nil
    )
}
