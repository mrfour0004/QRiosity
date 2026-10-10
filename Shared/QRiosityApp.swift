//
//  QRiosityApp.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import SwiftUI

@main
struct QRiosityApp: App {
    let barcodeImageStorage = BarcodeImageStorage.shared
    @StateObject var modalStore = ModalStore()

    var body: some Scene {
        WindowGroup {
            StoreRootView()
                .environment(\.barcodeImageStorage, barcodeImageStorage)
                .environmentObject(modalStore)
        }
    }
}


private struct StoreRootView: View {
    @State private var persistence: PersistenceController?
    @State private var didFail = false
    @State private var attempt = 0

    var body: some View {
        Group {
            if let persistence {
                ContentView().modelContainer(persistence.modelContainer)
            } else if didFail {
                ContentUnavailableView {
                    Label("Unable to Open Your Codes", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your data has been kept. Try opening it again.")
                } actions: {
                    Button("Try Again") { attempt += 1 }
                }
            } else {
                ProgressView("Opening Your Codes")
            }
        }
        .task(id: attempt) {
            didFail = false
            do {
                persistence = try PersistenceController.shared
            } catch {
                didFail = true
                print("Store open failed: \(error)")
            }
        }
    }
}
