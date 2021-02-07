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

    @State private var presentingRecord = false
    @State private var presentedRecord: CodeRecord?
    @State private var isSessionRunning = false

    var body: some View {
        NavigationView {
            ZStack {
                Scanner(isSessionRunning: $isSessionRunning)
                    .onCapture { metadataObject in
                        presentingRecord = true
                        isSessionRunning = false
                    }
                    .onAppear { isSessionRunning = true }
                    .onDisappear { isSessionRunning = false }
            }
            .sheet(
                isPresented: $presentingRecord,
                onDismiss: {
                    presentedRecord = nil
                    isSessionRunning = true
                },
                content: {
                    Text(presentedRecord?.stringValue ?? "record not found")
                }
            )
            .navigationBarTitle("Scanner", displayMode: .inline)
        }
    }

    private func onCaptureMetadataObject(_ metadataObject: AVMetadataMachineReadableCodeObject) -> Void {
        isSessionRunning = false
        presentingRecord = true
    }

    // MARK: - Generating Records

    private func store(_ metadataObject: AVMetadataMachineReadableCodeObject) {

    }

    private func present(_ record: CodeRecord) {

    }

}

