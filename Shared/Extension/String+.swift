//
//  String+.swift
//  QRiosity
//
//  Created by mrfour on 2021/10/3.
//  Copyright © 2021 mrfour. All rights reserved.
//

import Foundation

extension String {
    /// Returns a new string made by removing whitespaces and new lines from both ends of the String.
    var trimmed: String {
        trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
