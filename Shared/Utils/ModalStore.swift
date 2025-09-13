//
//  ModalStore.swift
//  QRiosity
//
//  Created by mrfour on 2022/1/7.
//  Copyright © 2022 mrfour. All rights reserved.
//

import Combine
import SwiftUI

/// A store that manages modal-related states.
@Observable
class ModalStore: ObservableObject {
    var presentedObject: (any Equatable)?

    var isPresenting: Bool { presentedObject != nil }
}
