//
//  CollectedList.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI
import SwiftData

struct CollectedList: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<CodeRecord> { $0.isFavorite == true }, sort: \CodeRecord.scannedAt)
    private var records: [CodeRecord]

    @EnvironmentObject private var modalStore: ModalStore

    var body: some View {
        NavigationView {
            ZStack {
                FlowingGradientBackground(palette: .collected)

                if records.isEmpty {
                    EmptyStateView(
                        title: "No Collected Items",
                        message: "Tap the heart icon on any scanned code to add it to your collection."
                    )
                    .padding(.bottom, 24)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(records) { record in
                                RecordView(record: record)
                                    .onTapGesture {
                                        if let url = record.url {
                                            withAnimation {
                                                modalStore.presentedObject = IdentifiableURL(url)
                                            }
                                        } else {
                                            withAnimation {
                                                modalStore.presentedObject = record
                                            }
                                        }
                                    }
                                    .onLongPressGesture {
                                        if record.url != nil {
                                            withAnimation {
                                                modalStore.presentedObject = record
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(.collected)
            .navigationBarTitleDisplayMode(.large)
            .scrollEdgeEffectStyle(.soft, for: .all)
        }
    }
}

struct CollectedList_Previews: PreviewProvider {
    static var previews: some View {
        CollectedList()
            .modelContainer(PersistenceController.preview.modelContainer)
    }
}
