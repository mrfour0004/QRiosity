//
//  Scanner.swift
//  QRiosity
//
//  Created by mrfour on 2020/12/14.
//

import AVFoundation
import AVScanner
import SwiftUI

struct Scanner: UIViewRepresentable {
    @Binding var isSessionRunning: Bool

    fileprivate var _onCapture: (AVMetadataMachineReadableCodeObject) -> Void = { _ in }
    fileprivate var onConfigure: () -> Void = {}
    fileprivate var onFailingConfigure: (Error) -> Void = { _ in }
    fileprivate var onSessionStart: () -> Void = {}
    fileprivate var onSessionFailStart: (Error) -> Void = { _ in }

    init(isSessionRunning: Binding<Bool>) {
        _isSessionRunning = isSessionRunning
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> AVScannerView {
        let scannerView = AVScannerView()
        scannerView.initSession()
        scannerView.delegate = context.coordinator
        scannerView.supportedMetadataObjectTypes = [.qr, .code128, .aztec, .pdf417]
        return scannerView
    }

    func updateUIView(_ uiView: AVScannerView, context: Context) {
        if isSessionRunning {
            uiView.startSession()
            uiView.videoPreviewLayer.frame = uiView.bounds
        } else {
            uiView.stopSession()
        }
    }

    // MARK: - Coordinating

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - AVScannerView Delegating

    func onCapture(perform: @escaping (AVMetadataMachineReadableCodeObject) -> Void) -> Self {
        var modified = self
        modified._onCapture = perform
        return modified
    }
}

extension Scanner {
    class Coordinator: NSObject, @MainActor AVScannerViewDelegate {
        private let parent: Scanner

        init(parent: Scanner) {
            self.parent = parent
        }

        // MARK: - AVScannerViewDelegate

        @MainActor
        func scannerViewDidFinishConfiguration(_ scannerView: AVScannerView) {
            parent.onConfigure()
        }

        @MainActor
        func scannerView(_ scannerView: AVScannerView, didFailConfigurationWithError error: Error) {
            parent.onFailingConfigure(error)
        }

        @MainActor
        func scannerViewDidStartSession(_ scannerView: AVScannerView) {
            parent.onSessionStart()
        }

        @MainActor
        func scannerView(_ scannerView: AVScannerView, didFailStartingSessionWithError error: Error) {
            parent.onSessionFailStart(error)
        }

        @MainActor
        func scannerView(_ scannerView: AVScannerView, didCapture metadataObject: AVMetadataMachineReadableCodeObject) {
            parent._onCapture(metadataObject)
        }
    }
}
