//
//  Scanner.swift
//  QRiosity
//
//  Created by mrfour on 2020/12/14.
//

import AVFoundation
import AVScanner
import SwiftUI

/// Bridges AVScanner session control and capture callbacks to SwiftUI.
struct Scanner: UIViewRepresentable {
    let isSessionRunning: Bool
    let onCapture: (AVMetadataMachineReadableCodeObject) -> Void

    func makeUIView(context: Context) -> AVScannerView {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)

        let session = AVCaptureSession()
        session.automaticallyConfiguresApplicationAudioSession = false
        let controller = AVCaptureSessionController(session: session)
        let view = AVScannerView(controller: controller)
        view.delegate = context.coordinator
        view.initSession()
        view.supportedMetadataObjectTypes = [.qr, .code128, .aztec, .pdf417, .code39]
        return view
    }

    func updateUIView(_ uiView: AVScannerView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateSession(uiView)
    }

    static func dismantleUIView(_ uiView: AVScannerView, coordinator: Coordinator) {
        coordinator.isConfigured = false
        uiView.delegate = nil
        uiView.stopSession()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, @MainActor AVScannerViewDelegate {
        var parent: Scanner
        var isConfigured = false

        init(parent: Scanner) {
            self.parent = parent
        }

        func updateSession(_ view: AVScannerView) {
            guard isConfigured else { return }
            if parent.isSessionRunning {
                view.startSession()
            } else {
                view.stopSession()
            }
        }

        func scannerViewDidFinishConfiguration(_ scannerView: AVScannerView) {
            isConfigured = true
            updateSession(scannerView)
        }

        func scannerViewDidStartSession(_ scannerView: AVScannerView) {
            if !isConfigured || !parent.isSessionRunning { scannerView.stopSession() }
        }

        func scannerView(_ scannerView: AVScannerView, didFailConfigurationWithError error: Error) {
            print("Scanner configuration failed: \(error)")
        }

        func scannerView(_ scannerView: AVScannerView, didFailStartingSessionWithError error: Error) {
            print("Scanner session failed to start: \(error)")
        }

        func scannerView(
            _ scannerView: AVScannerView,
            didCapture metadataObject: AVMetadataMachineReadableCodeObject
        ) {
            guard isConfigured, parent.isSessionRunning else { return }
            guard metadataObject.stringValue != nil else {
                scannerView.startSession()
                return
            }
            parent.onCapture(metadataObject)
        }
    }
}
