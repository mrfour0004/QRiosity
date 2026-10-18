//
//  ScannerView.swift
//  QRiosity
//
//  Created by mrfour on 2020/10/9.
//

import AVFoundation
import QRious
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
        AVScanner(
            supportedMetadataObjectTypes: [.qr, .code128, .aztec, .pdf417, .code39],
            isSessionRunning: shouldRunSession
        )
            .onCapture(store)
            .onError { error in
                print("Scanner failed: \(error)")
            }
            .ignoresSafeArea()
            .onAppear {
                try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                isVisible = true
            }
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
