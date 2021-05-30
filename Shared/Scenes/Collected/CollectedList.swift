//
//  CollectedList.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI

struct CollectedList: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == 1"),
        animation: .default)
    private var records: FetchedResults<CodeRecord>

    var body: some View {
        List {
            ForEach(records) { record in
                RecordView(record: record)
            }
        }
    }
}

struct CollectedList_Previews: PreviewProvider {
    static var previews: some View {
        CollectedList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
