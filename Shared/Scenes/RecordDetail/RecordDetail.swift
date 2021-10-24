//
//  RecordDetail.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/3.
//  Copyright © 2021 mrfour. All rights reserved.
//

import SwiftUI

struct RecordDetail: View {
    let record: CodeRecord

    private enum Const {
        static let titlePlaceholder = "Untitled"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            propertyItem(title: "Title", value: record.title ?? Const.titlePlaceholder)
            propertyItem(title: "Code Type", value: record.metadataObjectType)
            propertyItem(title: "Code Content", value: record.desc ?? Const.titlePlaceholder)

            if let url = record.url {
                propertyItem(title: "URL", value: url.absoluteString)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()

    }

    func propertyItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.avenir(.caption))
            Text(value)
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
        RecordDetail(record: makeCodeRecord())
    }
}
