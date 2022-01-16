//
//  ContentView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/2.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @EnvironmentObject var modalStore: ModalStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: true)],
        animation: .default)
    private var items: FetchedResults<CodeRecord>

    // MARK: - Initializers

    init() {
        let appearance = UITabBar.appearance()
        // will set in in the future
        appearance.barTintColor = nil
        appearance.unselectedItemTintColor = nil
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                scannerTab
                collectedTab
                historyTab
                settingsTab
            }
            .accentColor(.primary) // need a theme

            if let record = modalStore.presentedObject as? CodeRecord {
                VisualEffect(effect: UIBlurEffect(style: .light))
                    .zIndex(1)
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            modalStore.presentedObject = nil
                        }
                    }

                RecordDetail(record: record)
                    .zIndex(2)
            }
        }
    }

}


// MARK: - Subviews

private extension ContentView {

    var scannerTab: some View {
        ScannerView()
            .tabItem {
                Image(systemName: "qrcode.viewfinder")
                Text("Scan")
            }
    }

    var collectedTab: some View {
        CollectedList()
            .tabItem {
                Image(systemName: "tray.fill")
                Text("Collected")
            }
    }

    var historyTab: some View {
        HistoryView()
            .tabItem {
                Image(systemName: "rectangle.stack")
                Text("History")
            }
    }

    var settingsTab: some View {
        Text("Settings")
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
    }

    private func addItem() {
        withAnimation {
            let newItem = CodeRecord(context: viewContext)
            newItem.scannedAt = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
    @Environment(\.managedObjectContext)
    private static var viewContext

    static var previews: some View {
        ContentView()
            .environmentObject(modalStore)
    }

    static var modalStore: ModalStore = {
        let store = ModalStore()
        store.presentedObject = Self.makeCodeRecord()
        return store
    }()

    private static func makeCodeRecord() -> CodeRecord {
        let record = CodeRecord(context: viewContext)
        record.title = "code title"
        record.desc = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. "
        record.scannedAt = Date()
        record.stringValue = "this is the content of barcode"
        record.metadataObjectType = "QR"

        return record
    }
}
