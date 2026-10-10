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
    @State private var recordBeingLabeled: CodeRecord?
    @State private var saveFailed = false

    private func deleteAll() {
        do { try LabelStore.clearHistory(records, in: modelContext) }
        catch { saveFailed = true }
    }

    var body: some View {
        NavigationView {
            ZStack {
                FlowingGradientBackground(palette: .history)

                if records.isEmpty {
                    EmptyStateView(
                        title: "No records, yet!",
                        message: "Start scanning QR codes and barcodes to see your history here."
                    )
                    .padding(.bottom, 24)
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
                                    .contextMenu {
                                        Button("Details", systemImage: "info.circle") { modalStore.presentedObject = record }
                                        Button("Labels", systemImage: "tag") { recordBeingLabeled = record }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(item: $recordBeingLabeled) { record in LabelSelectionView(record: record) }
            .alert("Unable to Save", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Your changes could not be saved. Please try again.") }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .scrollEdgeEffectStyle(.soft, for: .all)
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
                        Text("Codes with labels will be kept. Other codes will be deleted.")
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
