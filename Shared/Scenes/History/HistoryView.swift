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
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: false)],
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
                        title: "No Scan History",
                        message: "Start scanning QR codes and barcodes to see your history here."
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
