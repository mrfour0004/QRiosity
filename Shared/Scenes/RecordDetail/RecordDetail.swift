//
//  RecordDetail.swift
//  QRiosity
//
//  Created by Claude on 2025-08-31.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftData
import SwiftUI
import UIKit

struct RecordDetail: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.barcodeImageStorage) private var barcodeImageStorage

    @Bindable var record: CodeRecord
    @State private var isPromptingDeletion = false
    @State private var isEditingTitle = false
    @State private var isCopied = false
    @State private var selectedDetent: PresentationDetent
    @State private var barcodeImage: UIImage?
    @State private var isLoadingBarcode = true

    init(record: CodeRecord) {
        self.record = record
        let initialHeight: CGFloat = record.is2DBarcode ? 440 : 360
        _selectedDetent = State(initialValue: .height(initialHeight))
    }

    private var isExpanded: Bool {
        selectedDetent == .height(textMetrics.expandedHeight)
    }

    private var collapsedHeight: CGFloat {
        record.is2DBarcode ? 440 : 360
    }

    private var windowSize: CGSize {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        return scene?.coordinateSpace.bounds.size ?? CGSize(width: 393, height: 852)
    }

    private var textMetrics: (needsExpansion: Bool, expandedHeight: CGFloat, collapsedTextHeight: CGFloat, expandedTextHeight: CGFloat) {
        let text = record.stringValue
        let font = UIFont.preferredFont(forTextStyle: .body)
        let availableWidth = max(windowSize.width - 48, 280)

        let singleLineHeight = font.lineHeight
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )

        let textHeight = ceil(boundingRect.height)
        let isMultiLine = textHeight > (singleLineHeight * 1.3)

        let baseHeight = collapsedHeight
        let additionalHeight = max(textHeight - singleLineHeight, 0)
        let maxAllowedHeight = windowSize.height * 0.85
        let calculatedExpandedHeight = min(baseHeight + additionalHeight + 20, maxAllowedHeight)

        return (
            needsExpansion: isMultiLine,
            expandedHeight: max(calculatedExpandedHeight, baseHeight + 50),
            collapsedTextHeight: ceil(singleLineHeight) + 4,
            expandedTextHeight: textHeight + 16
        )
    }

    private var availableDetents: Set<PresentationDetent> {
        let metrics = textMetrics
        if metrics.needsExpansion {
            return [.height(collapsedHeight), .height(metrics.expandedHeight)]
        } else {
            return [.height(collapsedHeight)]
        }
    }

    private var shortCodeType: String {
        record.metadataObjectType.components(separatedBy: ".").last ?? record.metadataObjectType
    }

    private var navigationTitleContent: some View {
        VStack(spacing: 0) {
            Text(record.title ?? "Untitled")
                .font(.avenir(.headline))
                .foregroundColor(.primary)
            Text(shortCodeType)
                .font(.avenir(.caption))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
    }

    private var closeButtonContent: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .symbolColorRenderingMode(.gradient)
        }
    }

    private var copyButtonContent: some View {
        Button {
            UIPasteboard.general.string = record.stringValue
            isCopied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                isCopied = false
            }
        } label: {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .symbolColorRenderingMode(.gradient)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .offUp)))
                .fontWeight(isCopied ? .bold : nil)
                .foregroundStyle(isCopied ? .blue : .primary)
        }
    }

    private var editButtonContent: some View {
        Button {
            isEditingTitle = true
        } label: {
            Image(systemName: "pencil")
                .symbolColorRenderingMode(.gradient)
        }
    }

    private var favoriteButtonContent: some View {
        Button {
            toggleFavorite()
        } label: {
            Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                .symbolColorRenderingMode(.gradient)
                .foregroundColor(record.isFavorite ? .red : .primary)
        }
    }

    private var deleteButtonContent: some View {
        Button {
            isPromptingDeletion = true
        } label: {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
        .confirmationDialog("Delete Record", isPresented: $isPromptingDeletion, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteRecord()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    qrCodeSection

                    VStack(spacing: 6) {
                        ZStack(alignment: .top) {
                            Text(record.stringValue)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .opacity(isExpanded ? 0 : 1)

                            Text(record.stringValue)
                                .lineLimit(nil)
                                .opacity(isExpanded ? 1 : 0)
                        }
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .frame(
                            maxHeight: isExpanded ? textMetrics.expandedTextHeight : textMetrics.collapsedTextHeight,
                            alignment: .top
                        )
                        .clipped()
                        .contentTransition(.opacity)

                        if textMetrics.needsExpansion {
                            Image(systemName: isExpanded ? "chevron.compact.up" : "chevron.compact.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard textMetrics.needsExpansion else { return }
                        selectedDetent = isExpanded ? .height(collapsedHeight) : .height(textMetrics.expandedHeight)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollEdgeEffectStyle(.soft, for: .all)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { navigationTitleContent }
            }
        }
        .safeAreaBar(edge: .bottom, spacing: 0) {
            bottomToolbar
        }
        .task(id: [record.metadataObjectType, record.stringValue]) {
            let type = record.metadataObjectType
            let content = record.stringValue
            barcodeImage = nil
            isLoadingBarcode = true
            let image = await DetailBarcodeRenderer.shared.image(type: type, content: content)
            guard !Task.isCancelled else { return }
            barcodeImage = image
            isLoadingBarcode = false
            // Favoriting while the image loads should still save the completed image.
            if record.isFavorite {
                saveImage()
            }
        }
        .presentationDetents(availableDetents, selection: $selectedDetent)
        .presentationDragIndicator(textMetrics.needsExpansion ? .visible : .hidden)
        .fullScreenCover(isPresented: $isEditingTitle) {
            PropertyEditor(
                record: record,
                keyPath: \.title,
                propertyName: "Title"
            )
        }
    }

    private var bottomToolbar: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 12) {
                deleteButtonContent
                copyButtonContent
                editButtonContent
                favoriteButtonContent

                Spacer(minLength: 12)

                closeButtonContent
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var qrCodeSection: some View {
        if let image = barcodeImage {
            Group {
                if record.is2DBarcode {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .frame(height: 200)
                } else {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .frame(height: 120)
                }
            }
        } else if isLoadingBarcode {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: record.is2DBarcode ? 200 : 120)
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundColor(.primary)
                .frame(height: 120)
        }
    }

    private func toggleFavorite() {
        record.isFavorite.toggle()

        record.isFavorite ? saveImage() : deleteImage()
        try? modelContext.save()
    }

    private func saveImage() {
        guard let image = barcodeImage else { return }
        barcodeImageStorage.saveImage(
            image,
            barcodeType: record.metadataObjectType,
            stringValue: record.stringValue
        )
    }

    private func deleteImage() {
        barcodeImageStorage.deleteImage(
            barcodeType: record.metadataObjectType,
            stringValue: record.stringValue
        )
    }

    private func deleteRecord() {
        dismiss()
        modelContext.delete(record)
        try? modelContext.save()
    }
}

/// Actor isolation keeps Core Image initialization and rendering off the UI executor.
private actor DetailBarcodeRenderer {
    static let shared = DetailBarcodeRenderer()

    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 24
        cache.totalCostLimit = 16 * 1024 * 1024
    }

    func image(type: String, content: String) -> UIImage? {
        let key = "\(type.utf8.count):\(type)\(content)" as NSString
        if let image = cache.object(forKey: key) {
            return image
        }
        guard let image = BarcodeGeneratorFactory.makeGenerator(type: type)?
            .generateImage(from: content) else {
            return nil
        }
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: key, cost: cost)
        return image
    }
}

struct RecordDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack {
                Text("Main Content")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: .constant(true)) {
            RecordDetail(record: PreviewHelper.sampleCodeRecord)
                .modelContainer(PreviewHelper.preview.modelContainer)
        }
    }
}

private enum PreviewHelper {
    static let preview = PersistenceController(inMemory: true)

    static var sampleCodeRecord: CodeRecord {
        let record = CodeRecord(
            stringValue: "https://www.example.com",
            metadataObjectType: "org.iso.QRCode",
            scannedAt: Date()
        )
        record.title = "Sample QR Code"
        record.desc = "This is a sample QR code for testing purposes"

        return record
    }
}
