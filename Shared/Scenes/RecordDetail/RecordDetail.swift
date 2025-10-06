//
//  RecordDetail.swift
//  QRiosity
//
//  Created by Claude on 2025-08-31.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftData
import SwiftUI

struct RecordDetail: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var record: CodeRecord
    @State private var isPromptingDeletion = false
    @State private var isEditingTitle = false
    @State private var isCopied = false
    @State private var contentHeight: CGFloat = 300
    @State private var barcodeHeight: CGFloat = 0

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
            VStack(spacing: 24) {
                qrCodeSection

                Text(record.stringValue)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .onSizeChange { size in
                contentHeight = size.height + 120
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { navigationTitleContent }
                ToolbarItem(placement: .bottomBar) { deleteButtonContent }
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) { copyButtonContent }
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) { editButtonContent }
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) { favoriteButtonContent }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) { closeButtonContent }
            }
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $isEditingTitle) {
            PropertyEditor(
                record: record,
                keyPath: \.title,
                propertyName: "Title"
            )
        }
    }

    @ViewBuilder
    private var qrCodeSection: some View {
        if let generator = BarcodeGeneratorFactory.makeGenerator(type: record.metadataObjectType),
           let image = generator.generateImage(from: record.stringValue)
        {
            GeometryReader { geometry in
                barcode(for: image, in: geometry.size)
                    // to avoid glitch before size is calculated
                    .opacity(barcodeHeight > 0 ? 1 : 0)
            }
            .frame(height: barcodeHeight > 0 ? barcodeHeight : (record.is2DBarcode ? 200 : 120))
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundColor(.primary)
                .frame(height: 120)
        }
    }

    private func barcode(for image: UIImage, in geometrySize: CGSize) -> some View {
        let availableWidth = geometrySize.width
        let calculatedBarcodeWidth: CGFloat
        let calculatedBarcodeHeight: CGFloat
        let horizontalPadding: CGFloat

        if record.is2DBarcode {
            let maxSize = min(availableWidth * 0.7, 200)
            calculatedBarcodeWidth = maxSize
            calculatedBarcodeHeight = maxSize
            horizontalPadding = (availableWidth - maxSize) / 2
        } else {
            calculatedBarcodeWidth = min(availableWidth * 0.9, 320)
            calculatedBarcodeHeight = min(calculatedBarcodeWidth * 0.375, 120) // 保持 8:3 的寬高比
            horizontalPadding = (availableWidth - calculatedBarcodeWidth) / 2
        }

        DispatchQueue.main.async {
            if barcodeHeight != calculatedBarcodeHeight {
                barcodeHeight = calculatedBarcodeHeight
            }
        }

        return Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: calculatedBarcodeWidth, height: calculatedBarcodeHeight)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
    }

    private func toggleFavorite() {
        record.isFavorite.toggle()
        try? modelContext.save()
    }

    private func deleteRecord() {
        dismiss()
        modelContext.delete(record)
        try? modelContext.save()
    }
}

struct RecordDetail_Previews: PreviewProvider {
    @State private static var showSheet = true

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
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.modelContext

        return controller
    }()

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
