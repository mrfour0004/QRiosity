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
        animation: .default)
    private var records: FetchedResults<CodeRecord>

    @EnvironmentObject private var modalStore: ModalStore

    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color(.displayP3, white: 0.96, opacity: 1)
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 32) {
                        Text("Collected")
                            .font(.avenir(.largeTitle))
                        ForEach(records) { record in
                            Button {
                                modalStore.presentedObject = record
                            } label: {
                                RecordView(record: record)
                            }
                        }
                    }
                    .padding()
                    .padding(.top, reader.safeAreaInsets.top)
                    .padding(.bottom, reader.safeAreaInsets.bottom)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct CollectedList_Previews: PreviewProvider {
    static var previews: some View {
        CollectedList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
