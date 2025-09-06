//
//  RecordDetail.swift
//  QRiosity
//
//  Created by Claude on 2025-08-31.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftUI

struct RecordDetail: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var modalStore: ModalStore

    @ObservedObject var record: CodeRecord
    @State private var isPromptingDeletion = false
    @State private var isEditingTitle = false

    private var shortCodeType: String {
        record.metadataObjectType.components(separatedBy: ".").last ?? record.metadataObjectType
    }

    private var navigationTitleContent: some View {
        VStack(spacing: 0) {
            Text(record.title ?? "Untitled")
                .font(.avenir(.headline))
                .foregroundColor(.primary)
            Text(shortCodeType)
                .font(.avenir(.caption))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
    }

    private var closeButtonContent: some View {
        Button {
            withAnimation {
                modalStore.presentedObject = nil
            }
        } label: {
            Image(systemName: "xmark")
        }
    }

    private var copyButtonContent: some View {
        Button {
            UIPasteboard.general.string = record.stringValue
        } label: {
            Image(systemName: "doc.on.doc")
        }
    }

    private var editButtonContent: some View {
        Button {
            isEditingTitle = true
        } label: {
            Image(systemName: "pencil")
        }
    }

    private var favoriteButtonContent: some View {
        Button {
            toggleFavorite()
        } label: {
            Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                .foregroundColor(record.isFavorite ? .red : .primary)
        }
    }

    private var deleteButtonContent: some View {
        Button {
            isPromptingDeletion = true
        } label: {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                qrCodeSection

                Text(record.stringValue)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    navigationTitleContent
                }

                ToolbarItem(placement: .bottomBar) {
                    deleteButtonContent
                }

                ToolbarSpacer(.fixed, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    copyButtonContent
                }

                ToolbarItem(placement: .bottomBar) {
                    editButtonContent
                }

                ToolbarItem(placement: .bottomBar) {
                    favoriteButtonContent
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    closeButtonContent
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $isEditingTitle) {
            PropertyEditor(
                record: record,
                keyPath: \.title,
                propertyName: "Title"
            )
        }
        .confirmationDialog("Delete Record", isPresented: $isPromptingDeletion, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteRecord()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var qrCodeSection: some View {
        Image(systemName: "qrcode")
            .font(.system(size: 120))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
    }

    private func toggleFavorite() {
        record.isFavorite.toggle()
        try? viewContext.save()
    }

    private func deleteRecord() {
        withAnimation {
            modalStore.presentedObject = nil
        }
        viewContext.delete(record)
        try? viewContext.save()
    }
}

struct RecordDetail_Previews: PreviewProvider {
    @State private static var showSheet = true

    static var previews: some View {
        NavigationStack {
            VStack {
                Text("Main Content")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: .constant(true)) {
            RecordDetail(record: PreviewHelper.sampleCodeRecord)
                .environment(\.managedObjectContext, PreviewHelper.preview.container.viewContext)
                .environmentObject(ModalStore())
        }
    }
}

private enum PreviewHelper {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        return controller
    }()

    static var sampleCodeRecord: CodeRecord {
        let context = preview.container.viewContext
        let record = CodeRecord(context: context)
        record.title = "Sample QR Code"
        record.desc = "This is a sample QR code for testing purposes"
        record.scannedAt = Date()
        record.stringValue = "https://www.example.com"
        record.metadataObjectType = "org.iso.QRCode"

        return record
    }
}
