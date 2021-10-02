//
//  ScannerView.swift
//  QRiosity
//
//  Created by mrfour on 2020/10/9.
//

import SwiftUI
import AVScanner
import AVFoundation

struct ScannerView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @State private var presentedRecord: CodeRecord?
    @State private var isSessionRunning = false

    var body: some View {
        NavigationView {
            ZStack {
                Scanner(isSessionRunning: $isSessionRunning)
                    .onCapture { metadataObject in
                        let existingRecord = viewContext.existingCodeRecord(withBarcode: metadataObject.stringValue!)
                        let record = existingRecord ?? CodeRecord.instantiate(with: metadataObject, in: viewContext)
                        record.scannedAt = Date() // update the scan time anyway

                        if viewContext.hasChanges {
                            try? viewContext.save()
                        }
                        
                        presentedRecord = record
                        isSessionRunning = false
                    }
                    .onAppear { isSessionRunning = true }
                    .onDisappear { isSessionRunning = false }
            }
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
                    } else {
                        Text(presentedRecord?.stringValue ?? "record not found")
                    }
                }
            )
            .navigationBarTitle("Scanner", displayMode: .inline)
        }
    }

    // MARK: - Generating Records

    private func store(_ metadataObject: AVMetadataMachineReadableCodeObject) {

    }

    private func present(_ record: CodeRecord) {

    }

}

