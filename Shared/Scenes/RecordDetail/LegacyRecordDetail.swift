//
//  LegacyRecordDetail.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/3.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftUI

struct PropertyAction {
    let iconName: String
    let action: () -> Void

    static func edit(_ action: @escaping () -> Void) -> PropertyAction {
        PropertyAction(iconName: "square.and.pencil", action: action)
    }

    static func copy(_ action: @escaping () -> Void) -> PropertyAction {
        PropertyAction(iconName: "doc.on.doc.fill", action: action)
    }

    static func share(_ action: @escaping () -> Void) -> PropertyAction {
        PropertyAction(iconName: "square.and.arrow.up", action: action)
    }
}

/// A legacy version of RecordDetail.
///
/// This style is legacy and doesn't fit the current liquid glass design, so we will make a new one later.
struct LegacyRecordDetail: View {
    @Environment(\.managedObjectContext) private var viewContext

    @EnvironmentObject private var modalStore: ModalStore

    private enum Const {
        static let titlePlaceholder = "Untitled"
    }

    // MARK: - Properties

    @ObservedObject
    var record: CodeRecord

    @State
    private var isPromptingDeletion = false

    @State
    private var showsCode = false

    @State
    private var isEditingTitle = false

    // MARK: - Computed Properties

    private var shortCodeType: String {
        return record.metadataObjectType.components(separatedBy: ".").last ?? record.metadataObjectType
    }

    // MARK: - Views

    var body: some View {
        VStack(spacing: 16) {
            content

            buttonStack
        }
        .padding()
        .fullScreenCover(isPresented: $isEditingTitle) {
            PropertyEditor(
                record: record,
                keyPath: \.title,
                propertyName: "Title"
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack {
            if showsCode {
                codeContent
                    .transition(.opacity)
            } else {
                listContent
                    .transition(.opacity)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showsCode)
    }

    @ViewBuilder
    private var listContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            propertyItem(
                title: "Title",
                value: record.title ?? Const.titlePlaceholder,
                action: .edit { isEditingTitle = true }
            )
            propertyItem(title: "Code Type", value: shortCodeType)

            propertyItem(
                title: "Code Content",
                value: record.stringValue,
                action: .copy {
                    UIPasteboard.general.string = record.stringValue
                }
            )

            if let url = record.url {
                propertyItem(title: "URL", value: url.absoluteString)
            }
        }
    }

    @ViewBuilder
    private var codeContent: some View {
        Image(systemName: "qrcode")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 200)
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showsCode.toggle()
            }
        } label: {
            Image(systemName: showsCode ? "list.dash" : "qrcode")
                .resizable()
        }
    }

    private var likeButton: some View {
        Button {
            record.isFavorite.toggle()

            // If the record is not favorite and also deleted from history, delete it permanently.
            if !record.isFavorite && record.isDeletedFromHistory {
                deleteRecord()
            }

            do {
                try viewContext.save()
            } catch {
                print("Failed to save favorite status: \(error.localizedDescription)")
            }
        } label: {
            Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                .resizable()
                .foregroundStyle(record.isFavorite ? .red : .secondary)
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

    private func propertyItem(title: String, value: String, action: PropertyAction? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                    .font(.avenir(.headline))
                    .fontWeight(.black)

                if let action = action {
                    Button(action: action.action) {
                        Image(systemName: action.iconName)
                            .font(.avenir(.headline))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(0.8)
                }

                Spacer()
            }
            .foregroundStyle(.primary)

            Text(value)
                .font(.avenir(.body))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LegacyRecordDetail_Previews: PreviewProvider {
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

            LegacyRecordDetail(record: makeCodeRecord())
        }
    }
}
