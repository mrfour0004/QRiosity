//
//  RecordDetail.swift
//  QRiosity
//
//  Created by Claude on 2025-08-31.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftUI

struct RecordDetail: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var modalStore: ModalStore

    @ObservedObject var record: CodeRecord
    @State private var isPromptingDeletion = false
    @State private var isEditingTitle = false
    @State private var contentHeight: CGFloat = 0
    @State private var currentSheetHeight: CGFloat = 0
    @State private var baseSheetHeight: CGFloat = 0
    @State private var fullContentTextHeight: CGFloat = 0
    @State private var twoLineTextHeight: CGFloat = 0

    private var shortCodeType: String {
        record.metadataObjectType.components(separatedBy: ".").last ?? record.metadataObjectType
    }

    private var calculatedInitialHeight: CGFloat {
        // Use contentHeight as fallback when twoLineTextHeight hasn't been measured yet
        // This prevents initial height from being too small causing ScrollView to be scrollable
        if twoLineTextHeight > 0 && needsExpansion {
            // When truncation is needed, calculate using measured two-line height
            let navigationHeight: CGFloat = 44
            let qrCodeHeight: CGFloat = 120
            let twoLineContentHeight = twoLineTextHeight + 50 // Add detailField padding and background
            let paddingAndSpacing: CGFloat = 24 * 3 + 16 * 2 // VStack spacing + main padding

            return navigationHeight + qrCodeHeight + twoLineContentHeight + paddingAndSpacing
        } else {
            return contentHeight
        }
    }

    private var expansionProgress: Double {
        let minHeight = calculatedInitialHeight
        let maxHeight = contentHeight
        guard maxHeight > minHeight else { return 0 }
        return min(max((currentSheetHeight - minHeight) / (maxHeight - minHeight), 0), 1)
    }

    private var needsExpansion: Bool {
        // Only need to check if text content is truncated
        return fullContentTextHeight > twoLineTextHeight && twoLineTextHeight > 0
    }

    private var availableDetents: Set<PresentationDetent> {
        if needsExpansion {
            return [.height(calculatedInitialHeight), .height(contentHeight)]
        } else {
            return [.height(calculatedInitialHeight)]
        }
    }

    private var dynamicLineLimit: Int? {
        guard needsExpansion else { return nil }

        switch expansionProgress {
        case ..<0.3:
            return 2
        case 0.3 ... 0.7:
            let progressRange = (expansionProgress - 0.3) / 0.4
            let estimatedLines = Int(2 + progressRange * 8) // Max expand to about 10 lines

            return estimatedLines
        default:
            return nil // unlimited
        }
    }

    var body: some View {
        NavigationView {
            GeometryReader { outerGeometry in
                ScrollView {
                    VStack(spacing: 24) {
                        qrCodeSection

                        detailSection
                    }
                    .padding()
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    let navigationBarHeight: CGFloat = 44
                                    let safeAreaTop = outerGeometry.safeAreaInsets.top
                                    let safeAreaBottom = outerGeometry.safeAreaInsets.bottom
                                    contentHeight = geometry.size.height + navigationBarHeight + safeAreaTop + safeAreaBottom + 32
                                }
                                .onChange(of: record.title) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        let navigationBarHeight: CGFloat = 44
                                        let safeAreaTop = outerGeometry.safeAreaInsets.top
                                        let safeAreaBottom = outerGeometry.safeAreaInsets.bottom
                                        contentHeight = geometry.size.height + navigationBarHeight + safeAreaTop + safeAreaBottom + 32
                                    }
                                }
                        }
                    )

                    // Hidden text measurement views
                    textMeasurementViews
                }
                .scrollDisabled(!needsExpansion || expansionProgress < 0.7)
                .background(
                    GeometryReader { _ in
                        Color.clear
                            .onAppear {
                                currentSheetHeight = outerGeometry.size.height
                            }
                            .onChange(of: outerGeometry.size.height) { _, newHeight in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    currentSheetHeight = newHeight
                                }
                            }
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
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

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            modalStore.presentedObject = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isEditingTitle = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .presentationDetents(availableDetents)
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $isEditingTitle) {
            PropertyEditor(
                record: record,
                keyPath: \.title,
                propertyName: "Title"
            )
        }
        .confirmationDialog("Delete Record", isPresented: $isPromptingDeletion, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteRecord()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var qrCodeSection: some View {
        Image(systemName: "qrcode")
            .font(.system(size: 120))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
    }

    private var detailSection: some View {
        VStack(spacing: 20) {
            detailField(
                title: "Content",
                value: record.stringValue,
                lineLimit: dynamicLineLimit,
                action: {
                    UIPasteboard.general.string = record.stringValue
                }
            )

            if let url = record.url {
                detailField(
                    title: "URL",
                    value: url.absoluteString
                )
            }
        }
    }

    private var textMeasurementViews: some View {
        VStack {
            // Measure full content height
            Text(record.stringValue)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            fullContentTextHeight = geometry.size.height
                        }
                        .onChange(of: record.stringValue) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                fullContentTextHeight = geometry.size.height
                            }
                        }
                    }
                )

            // Measure two-line content height
            Text(record.stringValue)
                .font(.body)
                .lineLimit(2)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            twoLineTextHeight = geometry.size.height
                        }
                        .onChange(of: record.stringValue) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                twoLineTextHeight = geometry.size.height
                            }
                        }
                    }
                )
        }
        .opacity(0)
        .frame(height: 0)
        .clipped()
    }

    private func detailField(title: String, value: String, lineLimit: Int? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                if let action = action {
                    Button(action: action) {
                        Image(systemName: title == "Title" ? "pencil" : "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.2), value: lineLimit)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func deleteRecord() {
        withAnimation {
            modalStore.presentedObject = nil
        }
        viewContext.delete(record)
        try? viewContext.save()
    }
}

struct RecordDetail_Previews: PreviewProvider {
    @Environment(\.managedObjectContext)
    private static var viewContext

    private static func makeCodeRecord() -> CodeRecord {
        let record = CodeRecord(context: viewContext)
        record.title = "Sample QR Code"
        record.desc = "This is a sample QR code for testing purposes"
        record.scannedAt = Date()
        record.stringValue = "https://www.example.com"
        record.metadataObjectType = "org.iso.QRCode"

        return record
    }

    static var previews: some View {
        RecordDetail(record: makeCodeRecord())
            .environmentObject(ModalStore())
    }
}
