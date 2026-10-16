//
//  ScannerView.swift
//  QRiosity
//
//  Created by mrfour on 2020/10/9.
//

import AVFoundation
import SwiftData
import SwiftUI

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var presentedRecord: CodeRecord?
    @State private var isVisible = false
    @State private var isProcessingCapture = false
    @State private var captureTask: Task<Void, Never>?

    private var shouldRunSession: Bool {
        isVisible && scenePhase == .active && presentedRecord == nil && !isProcessingCapture
    }

    var body: some View {
        Scanner(isSessionRunning: shouldRunSession, onCapture: store)
            .ignoresSafeArea()
            .safeAreaInset(edge: .top) {
                Text("Point your camera at a QR code or barcode.")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.5))
            }
            .onAppear { isVisible = true }
            .onDisappear {
                isVisible = false
                captureTask?.cancel()
            }
            .sheet(item: $presentedRecord) { record in
                if let url = record.url {
                    SafariView(url: url)
                } else {
                    RecordDetail(record: record)
                }
            }
            .sensoryFeedback(trigger: presentedRecord) {
                presentedRecord == nil ? nil : .success
            }
    }

    private func store(_ metadataObject: AVMetadataMachineReadableCodeObject) {
        guard shouldRunSession, let value = metadataObject.stringValue else { return }
        isProcessingCapture = true

        let existingRecord = modelContext.existingCodeRecord(withBarcode: value)
        let record = existingRecord ?? CodeRecord.insert(metadataObject, in: modelContext)
        record.scannedAt = .now
        try? modelContext.save()

        captureTask = Task {
            defer { isProcessingCapture = false }

            if let url = record.url {
                do {
                    let metadata = try await LinkMetadataFetcher.fetchMetadata(from: url)
                    try Task.checkCancellation()
                    record.updateMetadata(
                        title: metadata.title,
                        description: metadata.description,
                        previewImageURLString: metadata.previewImageURL
                    )
                    try? modelContext.save()
                } catch {
                    if !Task.isCancelled { print("Failed to fetch metadata: \(error.localizedDescription)") }
                }
            }

            guard !Task.isCancelled, isVisible else { return }
            presentedRecord = record
        }
    }
}
