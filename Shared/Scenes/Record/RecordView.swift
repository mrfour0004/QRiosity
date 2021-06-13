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
        HStack(alignment: .top, spacing: 8) {
            typeIcon

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    title
                    date
                }
                content
            }
        }
    }

    // MARK: - Subviews

    private var typeIcon: some View {
        Image(systemName: record.type == .url ? "link" : "barcode")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .padding(6)
            .foregroundColor(.white)
            .background(Color.black)
            .clipShape(Circle())
    }

    private var title: some View {
        HStack {
            Text(record.title ?? record.stringValue)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .font(.headline)

            Spacer()
        }
    }

    private var date: some View {
        Text("\(record.scannedAt, formatter: dateFormatter)")
            .font(.caption)
    }

    private var content: some View {
        HStack {
            Text(record.desc ?? record.stringValue)
                .multilineTextAlignment(.leading)
                .padding(8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .circular))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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

