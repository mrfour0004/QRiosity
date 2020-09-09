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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: true)],
        animation: .default)
    private var items: FetchedResults<CodeRecord>

    init() {
        let appearance = UITabBar.appearance()
        // will set in in the future
        appearance.barTintColor = nil
        appearance.unselectedItemTintColor = nil
    }

    var body: some View {
        TabView {
            Text("Scanner")
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }

            CollectedList()
                .tabItem {
                    Image(systemName: "tray.fill")
                    Text("Collected")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("History")
                }

            Text("Settings")
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .accentColor(.primary) // need a theme
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
    static var previews: some View {
        Group {
            NavigationView {
                ContentView()
            }
        }
    }
}
