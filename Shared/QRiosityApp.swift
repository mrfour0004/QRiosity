//
//  QRiosityApp.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import SwiftUI

@main
struct QRiosityApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var modalStore = ModalStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(persistenceController.modelContainer)
                .environmentObject(modalStore)
        }
    }
}
