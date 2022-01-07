//
//  ModalStore.swift
//  QRiosity
//
//  Created by mrfour on 2022/1/7.
//  Copyright © 2022 mrfour. All rights reserved.
//

import Combine

/// A store that manages modal-related states.
class ModalStore: ObservableObject {
    @Published var presentedObject: Any?
}
