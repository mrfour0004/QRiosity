//
//  HistoryView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<CodeRecord> { $0.isDeletedFromHistory == false }, sort: \CodeRecord.scannedAt, order: .reverse)
    private var records: [CodeRecord]

    @EnvironmentObject private var modalStore: ModalStore
    @State private var showingDeleteConfirmation = false

    private func deleteAll() {
        for record in records {
            record.isDeletedFromHistory = true

            if !record.isFavorite {
                modelContext.delete(record)
            }
        }

        do {
            try withAnimation {
                try modelContext.save()
            }
        } catch {
            print("Failed to delete all records: \(error.localizedDescription)")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .background(.regularMaterial)
                    .background(Image(.background1).resizable().scaledToFill().scaleEffect(2))

                if records.isEmpty {
                    EmptyStateView(
                        title: "No records, yet!",
                        message: "Start scanning QR codes and barcodes to see your history here."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(records, id: \.id) { record in
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Empty", systemImage: "trash.fill")
                            .labelStyle(.iconOnly)
                    }
                    .disabled(records.isEmpty)
                    .confirmationDialog("Delete All History", isPresented: $showingDeleteConfirmation) {
                        Button("Delete All", role: .destructive) {
                            deleteAll()
                        }
                    } message: {
                        Text("Empty history?")
                    }
                }
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .modelContainer(PersistenceController.preview.modelContainer)
    }
}
