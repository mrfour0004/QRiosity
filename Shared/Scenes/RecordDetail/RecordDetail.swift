//
//  RecordDetail.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/3.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftUI

struct RecordDetail: View {

    @Environment(\.managedObjectContext) private var viewContext

    @EnvironmentObject private var modalStore: ModalStore

    private enum Const {
        static let titlePlaceholder = "Untitled"
    }

    // MARK: - Properties

    let record: CodeRecord

    @State private var isPromptingDeletion = false

    // MARK: - Views

    var body: some View {
        VStack(spacing: 16) {
            content
            buttonStack
        }
        .padding()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            propertyItem(title: "Title", value: record.title ?? Const.titlePlaceholder)
            propertyItem(title: "Code Type", value: record.metadataObjectType)

            if let desc = record.desc {
                // shouldn't get here, technically
                propertyItem(title: "Code Content", value: desc)
            }

            if let url = record.url {
                propertyItem(title: "URL", value: url.absoluteString)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
        )

    }

    private var buttonStack: some View {
        HStack(alignment: .center, spacing: 16) {
            contentToggleButton
            likeButton
            deleteButton
            Spacer()
            closeButton
        }
        .buttonStyle(.roundedMaterial)
    }

    private var contentToggleButton: some View {
        Button {

        } label: {
            Image(systemName: "qrcode")
                .resizable()
        }
    }

    private var likeButton: some View {
        Button {
            record.isFavorite.toggle()

            if !record.isFavorite && record.isDeletedFromHistory {
                deleteRecord()
            }
        } label: {
            Image(systemName: "heart")
                .resizable()
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            isPromptingDeletion = true
        } label: {
            Image(systemName: "trash")
                .resizable()
        }
        .actionSheet(isPresented: $isPromptingDeletion) {
            ActionSheet(title: Text("Delete?"), buttons: [
                .destructive(Text("Detele"), action: deleteRecord),
                .cancel()
            ])
        }
        
    }

    private var closeButton: some View {
        Button {
            withAnimation {
                modalStore.presentedObject = nil
            }
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .frame(width: 20, height: 20)
        }
    }

    // MARK: - Utils

    private func deleteRecord() {
        withAnimation {
            modalStore.presentedObject = nil
        }
        viewContext.delete(record)
        try? viewContext.save()
    }

    private func propertyItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.avenir(.headline))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.avenir(.body))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecordDetail_Previews: PreviewProvider {
    @Environment(\.managedObjectContext)
    private static var viewContext

    private static func makeCodeRecord() -> CodeRecord {
        let record = CodeRecord(context: viewContext)
        record.title = "code title"
        record.desc = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. "
        record.scannedAt = Date()
        record.stringValue = "this is the content of barcode"
        record.metadataObjectType = "QR"

        return record
    }

    private static func makeURLCodeRecord() -> CodeRecord {
        let record = CodeRecord(context: viewContext)
        record.title = "code title"
        record.desc = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. "
        record.scannedAt = Date()
        record.stringValue = "this is the content of barcode"
        record.metadataObjectType = "QR"

        return record
    }

    static var previews: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.gray, Color.white],
                startPoint: UnitPoint(x: 0, y: 1),
                endPoint: UnitPoint(x: 0, y: 0)
            )
            .ignoresSafeArea()

            RecordDetail(record: makeCodeRecord())
        }
    }
}
