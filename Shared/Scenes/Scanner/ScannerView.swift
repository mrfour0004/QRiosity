//
//  ScannerView.swift
//  QRiosity
//
//  Created by mrfour on 2020/10/9.
//

import AVFoundation
import AVScanner
import SwiftData
import SwiftUI

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var presentedRecord: CodeRecord?
    @State private var isSessionRunning = false

    var body: some View {
        ZStack {
            Scanner(isSessionRunning: $isSessionRunning)
                .onCapture { metadataObject in
                    Task {
                        let existingRecord = modelContext.existingCodeRecord(withBarcode: metadataObject.stringValue!)
                        let record = existingRecord ?? CodeRecord.create(with: metadataObject, in: modelContext)
                        record.scannedAt = Date() // update the scan time anyway

                        try? modelContext.save()

                        // Fetch metadata for URLs
                        if let url = record.url {
                            do {
                                let metadata = try await LinkMetadataFetcher.fetchMetadata(from: url)
                                record.updateMetadata(
                                    title: metadata.title,
                                    description: metadata.description,
                                    previewImageURL: metadata.previewImageURL
                                )
                                try? modelContext.save()
                            } catch {
                                print("Failed to fetch metadata: \(error.localizedDescription)")
                            }
                        }

                        presentedRecord = record
                        isSessionRunning = false
                    }
                }
                .onAppear { isSessionRunning = true }
                .onDisappear { isSessionRunning = false }
        }
        .ignoresSafeArea()
        .sheet(
            isPresented: Binding(
                get: { presentedRecord != nil },
                set: { if !$0 { presentedRecord = nil } }
            ),
            onDismiss: {
                isSessionRunning = true
            },
            content: {
                if let url = presentedRecord?.url {
                    SafariView(url: url)
                }
                else if let presentedRecord {
                    RecordDetail(record: presentedRecord)
                }
            }
        )
        .sensoryFeedback(trigger: presentedRecord) {
            presentedRecord == nil ? nil : .success
        }
    }

    // MARK: - Generating Records

    private func store(_ metadataObject: AVMetadataMachineReadableCodeObject) {}

    private func present(_ record: CodeRecord) {}
}
