//
//  RecordView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI

/// A record row with the same tap, long-press, and label actions in every list.
struct RecordListItem: View {
    let record: CodeRecord

    @EnvironmentObject private var modalStore: ModalStore
    @State private var recordBeingLabeled: CodeRecord?

    var body: some View {
        HStack(spacing: 0) {
            if let url = record.url {
                RecordView(record: record)
                    .gesture(
                        LongPressGesture()
                            .exclusively(before: TapGesture())
                            .onEnded { value in
                                switch value {
                                case .first:
                                    present(record)
                                case .second:
                                    present(IdentifiableURL(url))
                                }
                            }
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { present(IdentifiableURL(url)) }
                    .accessibilityAction(named: Text("Details")) { present(record) }
            } else {
                RecordView(record: record)
                    .onTapGesture { present(record) }
                    .contextMenu {
                        Button("Details", systemImage: "info.circle") { present(record) }
                        Button("Labels", systemImage: "tag") { recordBeingLabeled = record }
                    }
            }
        }
        .sheet(item: $recordBeingLabeled) { record in LabelSelectionView(record: record) }
    }

    private func present(_ object: any Equatable) {
        withAnimation {
            modalStore.presentedObject = object
        }
    }
}

struct RecordView: View {
    enum Design {
        static let imageHeight = 100.0
        static let cornerRadius = 12.0
    }

    private let record: CodeRecord

    init(record: CodeRecord) {
        self.record = record
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            typeIcon

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    title
                    HStack(spacing: 8) {
                        date
                            .lineLimit(1)
                            .layoutPriority(1)

                        if record.hasLabels {
                            Rectangle()
                                .fill(.quaternary)
                                .frame(width: 1, height: 10)
                                .accessibilityHidden(true)

                            RecordLabelSummary(labels: record.labels)
                        }
                    }
                }
                .foregroundStyle(.primary)
                content
            }
        }
        .contentShape(Rectangle())
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
            .foregroundStyle(.primary)
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
                .foregroundStyle(record.title == nil ? Color.secondary : Color.primary)

            Spacer()
        }
    }

    private var date: some View {
        Text("\(record.scannedAt, formatter: dateFormatter)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 0) {
            record.previewImageURLString
                .flatMap(URL.init)
                .flatMap(imageThumbnail)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(4)

            VStack {
                HStack {
                    Text(record.recordDescription ?? record.stringValue)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .font(.avenir(.subheadline))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 12)
                }
                if let host = record.url?.host {
                    Spacer()
                    HStack {
                        Text(host.uppercased())
                            .font(.avenir(.caption2))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .frame(maxWidth: .infinity)
        }
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: Design.cornerRadius, style: .continuous))
    }

    @ViewBuilder
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
