//
//  CollectedList.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI

struct CollectedList: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == 1"),
        animation: .default
    )
    private var records: FetchedResults<CodeRecord>

    @EnvironmentObject private var modalStore: ModalStore
    @State private var backgroundOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .background(.regularMaterial)
                    .background(
                        Image(.background2)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(2)
                            .offset(x: backgroundOffset, y: backgroundOffset * 0.5)
                            .onAppear {
                                startBackgroundAnimation()
                            }
                    )

                if records.isEmpty {
                    EmptyStateView(
                        title: "No Collected Items",
                        message: "Tap the heart icon on any scanned code to add it to your collection."
                    )
                    .padding(.bottom, 24)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(records) { record in
                                Button {
                                    withAnimation {
                                        modalStore.presentedObject = record
                                    }
                                } label: {
                                    RecordView(record: record)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(.collected)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func startBackgroundAnimation() {
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) {
            backgroundOffset = 200
        }
    }
}

struct CollectedList_Previews: PreviewProvider {
    static var previews: some View {
        CollectedList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
