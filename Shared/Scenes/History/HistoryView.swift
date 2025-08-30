//
//  HistoryView.swift
//  QRiosity
//
//  Created by mrfour on 2020/9/9.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CodeRecord.scannedAt, ascending: false)],
        animation: .default)
    private var records: FetchedResults<CodeRecord>

    @EnvironmentObject private var modalStore: ModalStore

    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color(.displayP3, white: 0.96, opacity: 1)
                
                if records.isEmpty {
                    VStack {
                        Text("History")
                            .font(.avenir(.largeTitle))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, reader.safeAreaInsets.top)
                        
                        Spacer()
                        
                        EmptyStateView(
                            title: "No Scan History",
                            message: "Start scanning QR codes and barcodes to see your history here.",
                            systemImageName: "clock"
                        )
                        
                        Spacer()
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            Text("History")
                                .font(.avenir(.largeTitle))
                            
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
                        .padding(.top, reader.safeAreaInsets.top)
                        .padding(.bottom, reader.safeAreaInsets.bottom)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }


}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
