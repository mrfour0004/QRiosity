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

    func placeholder(in context: Context) -> RecordWidgetEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectRecordIntent, in context: Context) async -> RecordWidgetEntry {
        if let recordEntity = configuration.record {
            return RecordWidgetEntry(
                date: Date(),
                recordEntity: recordEntity
            )
        }
        
        if let defaultEntity = try? await CodeRecordEntity.defaultQuery.defaultResult() {
            return RecordWidgetEntry(
                date: Date(),
                recordEntity: defaultEntity
            )
        }
        
        return .placeholder
    }

    func timeline(for configuration: SelectRecordIntent, in context: Context) async -> Timeline<RecordWidgetEntry> {
        let entry: RecordWidgetEntry
        
        if let recordEntity = configuration.record {
            entry = RecordWidgetEntry(
                date: Date(),
                recordEntity: recordEntity
            )
        } else if let defaultEntity = try? await CodeRecordEntity.defaultQuery.defaultResult() {
            entry = RecordWidgetEntry(
                date: Date(),
                recordEntity: defaultEntity
            )
        } else {
            entry = .placeholder
        }

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
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
            Image(uiImage: image)
                .resizable()
                .frame(width: 150, height: 150)
                .scaledToFit()
                .background(.red.opacity(0.5))
                .clipShape(.rect(corners: .concentric))
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
