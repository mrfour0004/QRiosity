//
//  RecordView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI
import CoreData

struct RecordView: View {
    private var record: CodeRecord

    init(record: CodeRecord) {
        self.record = record
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(record.title ?? record.stringValue)
            Text("\(record.scannedAt, formatter: dateFormatter)")
                .font(.caption)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

//struct RecordView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecordView()
//    }
//}
