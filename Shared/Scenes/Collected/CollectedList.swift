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
        animation: .default
    )
    private var records: FetchedResults<CodeRecord>

    @EnvironmentObject private var modalStore: ModalStore

    var body: some View {
        NavigationView {
            ZStack {
                Color(.displayP3, white: 0.96, opacity: 1)
                    .ignoresSafeArea()

                if records.isEmpty {
                    EmptyStateView(
                        title: "No Collected Items",
                        message: "Tap the heart icon on any scanned code to add it to your collection."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(records) { record in
                                Button {
                                    withAnimation {
                                        modalStore.presentedObject = record
                                    }
                                } label: {
                                    RecordView(record: record)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Collected")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CollectedList_Previews: PreviewProvider {
    static var previews: some View {
        CollectedList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
