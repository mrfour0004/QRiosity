//
//  SelectRecordIntent.swift
//  RecordWidget
//
//  Created by AL02413554 on 2025/10/26.
//  Copyright © 2025 mrfour. All rights reserved.
//

import AppIntents

struct SelectRecordIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Record"
    static var description = IntentDescription("Choose a barcode from your collected items to display in the widget.")

    @Parameter(title: "Collected Barcode")
    var record: CodeRecordEntity?

    @Parameter(title: "Show Title", default: true)
    var showsTitle: Bool

    init(record: CodeRecordEntity? = nil, showsTitle: Bool = true) {
        self.record = record
        self.showsTitle = showsTitle
    }

    init() {
        self.record = nil
        self.showsTitle = true
    }
}
