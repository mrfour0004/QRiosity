//
//  HistoryView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: true)],
        animation: .default)
    private var records: FetchedResults<CodeRecord>

    var body: some View {

        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                Text("Placeholder")
                    .font(.title)
                ForEach(records) { record in
                    RecordView(record: record)
                }
            }
            .padding()
        }
    }


}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
