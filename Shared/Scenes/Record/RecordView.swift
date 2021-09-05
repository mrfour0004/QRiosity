//
//  RecordView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI
import CoreData

struct RecordView: View {
    enum Design {
        static let imageHeight: CGFloat = 100
        static let cornerRadius: CGFloat = 12
    }

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
                .font(.avenir(.headline))

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
            
            VStack {
                HStack {
                    Text(record.desc ?? record.stringValue)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .font(.avenir(.footnote))
                    Spacer(minLength: 12)
                }
                if let host = record.url?.host {
                    Spacer()
                    HStack {
                        Text(host.uppercased())
                            .font(.avenir(.caption2))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Design.cornerRadius, style: .circular))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
        .clipped()
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

//struct RecordView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecordView()
//    }
//}

