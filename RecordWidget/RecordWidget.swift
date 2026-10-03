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
            showsTitle: configuration.showsTitle,
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
            RecordWidgetEntry(date: Date(), recordEntity: $0, showsTitle: configuration.showsTitle, image: image(for: $0))
        } ?? .placeholder

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: - Loading image for barcode

    private func image(for entity: CodeRecordEntity) -> UIImage? {
        if let image = imageStorage.loadImage(
            barcodeType: entity.metadataObjectType,
            stringValue: entity.stringValue
        ) {
            return image
        }

        guard let generator = BarcodeGeneratorFactory.makeGenerator(type: entity.metadataObjectType),
              let image = generator.generateImage(from: entity.stringValue)
        else {
            return nil
        }

        imageStorage.saveImage(
            image,
            barcodeType: entity.metadataObjectType,
            stringValue: entity.stringValue
        )
        return image
    }
}

// MARK: - Widget Entry

struct RecordWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let stringValue: String
    let showsTitle: Bool
    let isLinear: Bool
    private(set) var image: UIImage?

    init(date: Date, recordEntity: CodeRecordEntity, showsTitle: Bool = true, image: UIImage? = nil) {
        self.date = date
        self.title = recordEntity.title
        self.stringValue = recordEntity.stringValue
        self.isLinear = !["QRCode", "Aztec", "PDF417"].contains(
            recordEntity.metadataObjectType.split(separator: ".").last.map(String.init) ?? ""
        )
        self.showsTitle = showsTitle
        self.image = image
    }

    init(date: Date, title: String, stringValue: String, showsTitle: Bool = true, isLinear: Bool = false, image: UIImage? = nil) {
        self.date = date
        self.title = title
        self.stringValue = stringValue
        self.isLinear = isLinear
        self.showsTitle = showsTitle
        self.image = image
    }
}

extension RecordWidgetEntry {
    static let placeholder = RecordWidgetEntry(
        date: Date(),
        title: "No favorite records",
        stringValue: "",
        showsTitle: true
    )
}

// MARK: - Widget Views

struct RecordWidgetEntryView: View {
    var entry: RecordWidgetEntry

    private var isLinear: Bool {
        entry.isLinear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isLinear ? "barcode" : "qrcode")
                    .foregroundStyle(Color(red: 0.12, green: 0.44, blue: 0.48))
                    .accessibilityHidden(true)
                Text(verbatim: entry.title)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color(red: 0.13, green: 0.23, blue: 0.30))
            .padding(.horizontal, 4)

            if let image = entry.image {
                VStack(spacing: isLinear ? 8 : 5) {
                    Group {
                        if isLinear {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .widgetAccentedRenderingMode(.fullColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .widgetAccentedRenderingMode(.fullColor)
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .accessibilityHidden(true)

                    if entry.showsContent {
                        Text(verbatim: entry.stringValue)
                            .font(.system(.caption2, design: .monospaced))
                            .tracking(isLinear ? 1.2 : 0)
                            .foregroundStyle(Color(red: 0.22, green: 0.29, blue: 0.33))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(isLinear ? 14 : 10)
                .background(.white, in: ContainerRelativeShape())
                .overlay {
                    ContainerRelativeShape()
                        .strokeBorder(.black.opacity(0.06), lineWidth: 1)
                }
                .accessibilityLabel(Text(verbatim: entry.stringValue))
            } else {
                Image(systemName: isLinear ? "barcode" : "qrcode")
                    .font(.largeTitle)
                    .foregroundStyle(Color(red: 0.12, green: 0.44, blue: 0.48))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(Text(verbatim: entry.title))
            }
        }
        .padding(14)
    }
}

private struct RecordWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.87, green: 0.96, blue: 0.93),
                Color(red: 0.91, green: 0.94, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.35))
                .frame(width: 150, height: 150)
                .offset(x: 45, y: -85)
        }
        .clipped()
    }
}

// MARK: - Widget Configuration

struct RecordWidget2D: Widget {
    let kind: String = "RecordWidget2D"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRecordIntent.self, provider: RecordWidgetProvider(filterType: .twoDimensional)) { entry in
            RecordWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    RecordWidgetBackground()
                }
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
                .containerBackground(for: .widget) {
                    RecordWidgetBackground()
                }
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
        title: "Sample Code 39",
        stringValue: "1234567890",
        isLinear: true,
        image: Code39Generator().generateImage(from: "1234567890")
    )
}
