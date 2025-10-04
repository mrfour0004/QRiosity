//
//  RecordView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import CoreData
import SwiftUI

struct RecordView: View {
    enum Design {
        static let imageHeight = 100.0
        static let cornerRadius = 12.0
    }

    private var record: CodeRecord

    init(record: CodeRecord) {
        self.record = record
    }

    var body: some View {
        // isFault check is necessary to avoid crash
        if record.isFault {
            #if DEBUG
            Text("Record is Fault")
            #else
            EmptyView()
            #endif
        } else {
            HStack(alignment: .top, spacing: 8) {
                typeIcon

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        title
                        date
                    }
                    .foregroundStyle(Color(.primary))
                    content
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var typeIcon: some View {
        let iconName = record.type == .url
            ? "link"
            : record.is2DBarcode ? "qrcode" : "barcode"
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .padding(6)
            .foregroundStyle(Color(.primary))
            .fontWeight(.bold)
            .fontDesign(.rounded)
            .glassEffect(in: Circle())
    }

    private var title: some View {
        HStack {
            Text(record.title ?? "Untitled")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .font(.avenir(.headline))
                .foregroundStyle(record.title == nil ? Color(.lightGray) : Color(.primary))

            Spacer()
        }
    }

    private var date: some View {
        Text("\(record.scannedAt, formatter: dateFormatter)")
            .font(.caption)
    }

    private var content: some View {
        HStack(spacing: 0) {
            record.previewImageURLString
                .flatMap(URL.init)
                .flatMap(imageThumbnail)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(4)

            VStack {
                HStack {
                    Text(record.desc ?? record.stringValue)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .font(.avenir(.subheadline))
                        .foregroundStyle(Color(.primary))
                    Spacer(minLength: 12)
                }
                if let host = record.url?.host {
                    Spacer()
                    HStack {
                        Text(host.uppercased())
                            .font(.avenir(.caption2))
                            .foregroundStyle(Color(.lightGray))
                        Spacer()
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: Design.cornerRadius, style: .continuous))
    }

    private func imageThumbnail(for url: URL) -> some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty, .failure:
                imagePlaceholder
            @unknown default:
                imagePlaceholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: Design.imageHeight)
    }

    private var imagePlaceholder: some View {
        Color(.displayP3, red: 0.9, green: 0.9, blue: 0.9, opacity: 1)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

// struct RecordView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecordView()
//    }
// }
