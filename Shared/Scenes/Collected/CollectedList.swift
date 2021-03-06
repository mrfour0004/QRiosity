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
        GeometryReader { reader in
            ZStack {
                Color(.displayP3, white: 0.96, opacity: 1)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 32) {
                        Text("Placeholder")
                            .font(.title)
                        ForEach(records) { record in
                            RecordView(record: record)
                        }
                    }
                    .padding()
                    .padding(.top, reader.safeAreaInsets.top)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct CollectedList_Previews: PreviewProvider {
    static var previews: some View {
        CollectedList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
