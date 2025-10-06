//
//  ContentView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var modalStore: ModalStore

    @Query(sort: \CodeRecord.scannedAt, order: .forward)
    private var items: [CodeRecord]

    // MARK: - Initializers

    init() {
        let appearance = UITabBar.appearance()
        // will set in in the future
        appearance.barTintColor = nil
        appearance.unselectedItemTintColor = nil
    }

    // MARK: - Body

    var body: some View {
        TabView {
            Tab("Scan", systemImage: "qrcode.viewfinder", role: .search) {
                ScannerView()
            }
            Tab(.collected, systemImage: "tray.fill") {
                CollectedList()
            }
            Tab("History", systemImage: "rectangle.stack") {
                HistoryView()
            }
//            Tab("Settings", systemImage: "gearshape") {
//                Text("Settings")
//            }
        }
        .sheet(item: Binding<CodeRecord?>(
            get: { modalStore.presentedObject as? CodeRecord },
            set: { modalStore.presentedObject = $0 }
        )) { record in
            RecordDetail(record: record)
        }
        .sheet(item: Binding<IdentifiableURL?>(
            get: { modalStore.presentedObject as? IdentifiableURL },
            set: { modalStore.presentedObject = $0 }
        )) { url in
            SafariView(url: url())
        }
    }
}

// MARK: - Subviews

private extension ContentView {
    private func addItem() {
        withAnimation {
            let newItem = CodeRecord(stringValue: "Sample", metadataObjectType: "QR")
            modelContext.insert(newItem)

            do {
                try modelContext.save()
            } catch {
                fatalError("Unresolved error \(error)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                modelContext.delete(items[index])
            }

            do {
                try modelContext.save()
            } catch {
                fatalError("Unresolved error \(error)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(modalStore)
            .modelContainer(PersistenceController.preview.modelContainer)
    }

    static var modalStore: ModalStore = {
        let store = ModalStore()
        store.presentedObject = Self.makeCodeRecord()
        return store
    }()

    private static func makeCodeRecord() -> CodeRecord {
        let record = CodeRecord(stringValue: "this is the content of barcode", metadataObjectType: "QR")
        record.title = "code title"
        record.desc = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. "

        return record
    }
}
