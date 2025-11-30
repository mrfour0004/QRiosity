//
//  RecordWidgetBundle.swift
//  RecordWidget
//
//  Created by AL02413554 on 2025/10/10.
//  Copyright © 2025 mrfour. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct RecordWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        RecordWidget2D()
        RecordWidget1D()
    }
}
